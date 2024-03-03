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
import docspell.store.qb.DSL._
import docspell.store.records._

import db.migration.data.{
  PeriodicDueItemsArgs => PeriodicDueItemsArgsLegacy,
  PeriodicQueryArgs => PeriodicQueryArgsLegacy,
  _
}
import doobie._
import doobie.implicits._
import io.circe.syntax._
import org.flywaydb.core.api.migration.Context

object MigrateDueItemTasks extends TransactorSupport with JsonCodecs {

  val logger = docspell.logging.getLogger[IO]

  def run(ctx: Context) =
    migratePeriodicItemTasks.transact(mkTransactor(ctx))

  def migratePeriodicItemTasks: ConnectionIO[Unit] =
    for {
      tasks2 <- RPeriodicTask.findByTask(PeriodicDueItemsArgsOld.taskName)
      tasks3 <- RPeriodicTask.findByTask(PeriodicQueryArgsOld.taskName)
      size = tasks2.size + tasks3.size
      _ <- Sync[ConnectionIO].delay(
        logger.info(s"Starting to migrate $size user tasks")
      )
      _ <- tasks2.traverse(migratePeriodicDueItemsTask)
      _ <- tasks3.traverse(migratePeriodicQueryTask)
      _ <- RPeriodicTask.setEnabledByTask(PeriodicQueryArgsOld.taskName, enabled = false)
      _ <- RPeriodicTask.setEnabledByTask(
        PeriodicDueItemsArgsOld.taskName,
        enabled = false
      )
    } yield ()

  private def migratePeriodicQueryTask(old: RPeriodicTask): ConnectionIO[Int] =
    old.args
      .parseJsonAs[PeriodicQueryArgsOld]
      .leftMap { ex =>
        logger.error(ex)(s"Error migrating tasks")
        0.pure[ConnectionIO]
      }
      .map { oldArgs =>
        val ref = oldArgs.channel match {
          case Right(c)  => saveChannel(c, oldArgs.account)
          case Left(ref) => ref.pure[ConnectionIO]
        }

        ref.flatMap(channelRef =>
          RPeriodicTask.updateTask(
            old.id,
            PeriodicQueryArgsLegacy.taskName,
            PeriodicQueryArgsLegacy(
              oldArgs.account,
              NonEmptyList.of(channelRef),
              oldArgs.query,
              oldArgs.bookmark,
              oldArgs.baseUrl,
              oldArgs.contentStart
            ).asJson.noSpaces
          )
        )
      }
      .fold(identity, identity)

  private def migratePeriodicDueItemsTask(old: RPeriodicTask): ConnectionIO[Int] =
    old.args
      .parseJsonAs[PeriodicDueItemsArgsOld]
      .leftMap { ex =>
        logger.error(ex)(s"Error migrating tasks")
        0.pure[ConnectionIO]
      }
      .map { oldArgs =>
        val ref = oldArgs.channel match {
          case Right(c)  => saveChannel(c, oldArgs.account)
          case Left(ref) => ref.pure[ConnectionIO]
        }

        ref.flatMap(channelRef =>
          RPeriodicTask.updateTask(
            old.id,
            PeriodicDueItemsArgsLegacy.taskName,
            PeriodicDueItemsArgsLegacy(
              oldArgs.account,
              NonEmptyList.of(channelRef),
              oldArgs.remindDays,
              oldArgs.daysBack,
              oldArgs.tagsInclude,
              oldArgs.tagsExclude,
              oldArgs.baseUrl
            ).asJson.noSpaces
          )
        )
      }
      .fold(identity, identity)

  private def saveChannel(ch: Channel, account: AccountId): ConnectionIO[ChannelRef] =
    (for {
      newId <- OptionT.liftF(Ident.randomId[ConnectionIO])
      userId <- OptionT(findIdByAccountId(account))
      r <- RNotificationChannel.fromChannel(ch, newId, userId)
      _ <- OptionT.liftF(RNotificationChannel.insert(r))
      _ <- OptionT.liftF(
        Sync[ConnectionIO].delay(logger.debug(s"Created channel $r for $account"))
      )
      ref = r.asRef
    } yield ref)
      .getOrElseF(Sync[ConnectionIO].raiseError(new Exception("User not found!")))

  def findIdByAccountId(accountId: AccountId): ConnectionIO[Option[Ident]] =
    sql"select u.uid from user_ u where u.cid = ${accountId.collective} and u.login = ${accountId.user}"
      .query[Ident]
      .option
}
