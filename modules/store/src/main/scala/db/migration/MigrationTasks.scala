/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration

import cats.data.{NonEmptyList, OptionT}
import cats.effect.{IO, Sync}
import cats.implicits._

import docspell.common._
import docspell.common.syntax.StringSyntax._
import docspell.notification.api._
import docspell.store.queries.QLogin
import docspell.store.records._

import db.migration.data._
import doobie._
import doobie.implicits._
import doobie.util.transactor.Strategy
import emil.MailAddress
import emil.javamail.syntax._
import io.circe.syntax._
import io.circe.{Decoder, Encoder}
import org.flywaydb.core.api.migration.Context

trait MigrationTasks {

  def logger: org.log4s.Logger

  implicit val jsonEncoder: Encoder[MailAddress] =
    Encoder.encodeString.contramap(_.asUnicodeString)
  implicit val jsonDecoder: Decoder[MailAddress] =
    Decoder.decodeString.emap(MailAddress.parse)

  def migrateDueItemTasks: ConnectionIO[Unit] =
    for {
      tasks <- RPeriodicTask.findByTask(NotifyDueItemsArgs.taskName)
      _ <- Sync[ConnectionIO].delay(
        logger.info(s"Starting to migrate ${tasks.size} user tasks")
      )
      _ <- tasks.traverse(migrateDueItemTask1)
      _ <- RPeriodicTask.setEnabledByTask(NotifyDueItemsArgs.taskName, false)
    } yield ()

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
      _ <- RPeriodicTask.setEnabledByTask(PeriodicQueryArgsOld.taskName, false)
      _ <- RPeriodicTask.setEnabledByTask(PeriodicDueItemsArgsOld.taskName, false)
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
            PeriodicQueryArgs.taskName,
            PeriodicQueryArgs(
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
            PeriodicDueItemsArgs.taskName,
            PeriodicDueItemsArgs(
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
      userData <- OptionT(QLogin.findUser(account))
      userId = userData.account.userId
      r <- RNotificationChannel.fromChannel(ch, newId, userId)
      _ <- OptionT.liftF(RNotificationChannel.insert(r))
      _ <- OptionT.liftF(
        Sync[ConnectionIO].delay(logger.debug(s"Created channel $r for $account"))
      )
      ref = r.asRef
    } yield ref)
      .getOrElseF(Sync[ConnectionIO].raiseError(new Exception("User not found!")))

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
                PeriodicDueItemsArgs.taskName,
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
  ): OptionT[ConnectionIO, PeriodicDueItemsArgs] = {
    val recs = old.recipients
      .map(MailAddress.parse)
      .flatMap {
        case Right(m) => Some(m)
        case Left(err) =>
          logger.warn(s"Cannot read mail address: $err. Skip this while migrating.")
          None
      }

    for {
      userData <- OptionT(QLogin.findUser(old.account))
      userId = userData.account.userId
      id <- OptionT.liftF(Ident.randomId[ConnectionIO])
      now <- OptionT.liftF(Timestamp.current[ConnectionIO])
      chName = Some("migrate notify items")
      ch = RNotificationChannelMail(
        id,
        userId,
        chName,
        old.smtpConnection,
        recs,
        now
      )
      _ <- OptionT.liftF(RNotificationChannelMail.insert(ch))
      args = PeriodicDueItemsArgs(
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

  def mkTransactor(ctx: Context): Transactor[IO] = {
    val xa = Transactor.fromConnection[IO](ctx.getConnection)
    Transactor.strategy.set(xa, Strategy.void) // transactions are handled by flyway
  }
}
