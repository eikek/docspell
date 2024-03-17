/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.common

import cats.data.{NonEmptyList, OptionT}
import cats.effect.{IO, Sync}
import cats.implicits._

import docspell.common._
import docspell.common.syntax.StringSyntax._
import docspell.notification.api._
import docspell.store.qb.DML
import docspell.store.qb.DSL._
import docspell.store.records.{RNotificationChannelMail, RPeriodicTask}

import db.migration.data.{PeriodicDueItemsArgs => PeriodicDueItemsArgsLegacy, _}
import doobie._
import doobie.implicits._
import emil.MailAddress
import emil.javamail.syntax._
import io.circe.syntax._
import org.flywaydb.core.api.migration.Context

object MigrateNotifyTasks extends TransactorSupport {
  val logger = docspell.logging.getLogger[IO]

  def run(ctx: Context): IO[Unit] =
    migrateDueItemTasks.transact(mkTransactor(ctx))

  def migrateDueItemTasks: ConnectionIO[Unit] =
    for {
      tasks <- RPeriodicTask.findByTask(NotifyDueItemsArgs.taskName)
      _ <- Sync[ConnectionIO].delay(
        logger.info(s"Starting to migrate ${tasks.size} user tasks")
      )
      _ <- tasks.traverse(migrateDueItemTask1)
      _ <- RPeriodicTask.setEnabledByTask(NotifyDueItemsArgs.taskName, enabled = false)
    } yield ()

  private def migrateDueItemTask1(old: RPeriodicTask): ConnectionIO[Int] = {
    val converted = old.args
      .parseJsonAs[NotifyDueItemsArgs]
      .leftMap(_.getMessage())
      .map(convertArgs)

    converted match {
      case Right(args) =>
        val task = args
          .semiflatMap(a =>
            RPeriodicTask
              .updateTask(
                old.id,
                PeriodicDueItemsArgsLegacy.taskName,
                a.asJson.noSpaces
              )
          )
          .getOrElse(0)

        Sync[ConnectionIO].delay(logger.info(s"Converting user task: $old")) *> task

      case Left(err) =>
        logger.error(s"Error converting user task: $old. $err")
        0.pure[ConnectionIO]
    }
  }

  private def convertArgs(
      old: NotifyDueItemsArgs
  ): OptionT[ConnectionIO, PeriodicDueItemsArgsLegacy] = {
    val recs = old.recipients
      .map(MailAddress.parse)
      .flatMap {
        case Right(m) => Some(m)
        case Left(err) =>
          logger.warn(s"Cannot read mail address: $err. Skip this while migrating.")
          None
      }

    for {
      userId <- OptionT(findIdByAccountId(old.account))
      id <- OptionT.liftF(Ident.randomId[ConnectionIO])
      now <- OptionT.liftF(Timestamp.current[ConnectionIO])
      connId <- OptionT(findSmtpConnectionId(old.smtpConnection, userId))
      chName = Some("migrate notify items")
      ch = RNotificationChannelMail(
        id,
        userId,
        chName,
        connId,
        recs,
        now
      )
      _ <- OptionT.liftF(insert(ch))
      args = PeriodicDueItemsArgsLegacy(
        old.account,
        NonEmptyList.of(ChannelRef(ch.id, ChannelType.Mail, chName)),
        old.remindDays,
        old.daysBack,
        old.tagsInclude,
        old.tagsExclude,
        old.itemDetailUrl
      )
    } yield args
  }

  def findIdByAccountId(accountId: AccountId): ConnectionIO[Option[Ident]] =
    sql"select u.uid from user_ u where u.cid = ${accountId.collective} and u.login = ${accountId.user}"
      .query[Ident]
      .option

  def findSmtpConnectionId(name: Ident, userId: Ident): ConnectionIO[Option[Ident]] =
    sql"select id from useremail where uid = $userId and (name = $name or id = $name)"
      .query[Ident]
      .option

  // insert without 'name' column, it was added afterwards
  def insert(r: RNotificationChannelMail): ConnectionIO[Int] = {
    val t = RNotificationChannelMail.T
    DML.insert(
      t,
      NonEmptyList.of(t.id, t.uid, t.connection, t.recipients, t.created),
      sql"${r.id},${r.uid},${r.connection},${r.recipients},${r.created}"
    )
  }
}
