/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration

import cats.data.NonEmptyList
import cats.effect.{IO, Sync}
import cats.implicits._

import docspell.common._
import docspell.common.syntax.StringSyntax._
import docspell.notification.api.Channel
import docspell.notification.api.PeriodicDueItemsArgs
import docspell.store.records.RPeriodicTask

import doobie._
import doobie.implicits._
import doobie.util.transactor.Strategy
import emil.MailAddress
import emil.javamail.syntax._
import io.circe.Encoder
import io.circe.syntax._
import org.flywaydb.core.api.migration.Context

trait MigrationTasks {

  def logger: org.log4s.Logger

  implicit val jsonEncoder: Encoder[MailAddress] =
    Encoder.encodeString.contramap(_.asUnicodeString)

  def migrateDueItemTasks: ConnectionIO[Unit] =
    for {
      tasks <- RPeriodicTask.findByTask(NotifyDueItemsArgs.taskName)
      _ <- Sync[ConnectionIO].delay(
        logger.info(s"Starting to migrate ${tasks.size} user tasks")
      )
      _ <- tasks.traverse(migrateDueItemTask1)
      _ <- RPeriodicTask.setEnabledByTask(NotifyDueItemsArgs.taskName, false)
    } yield ()

  def migrateDueItemTask1(old: RPeriodicTask): ConnectionIO[Int] = {
    val converted = old.args
      .parseJsonAs[NotifyDueItemsArgs]
      .leftMap(_.getMessage())
      .flatMap(convertArgs)

    converted match {
      case Right(args) =>
        Sync[ConnectionIO].delay(logger.info(s"Converting user task: $old")) *>
          RPeriodicTask.updateTask(
            old.id,
            PeriodicDueItemsArgs.taskName,
            args.asJson.noSpaces
          )

      case Left(err) =>
        logger.error(s"Error converting user task: $old. $err")
        0.pure[ConnectionIO]
    }
  }

  def convertArgs(old: NotifyDueItemsArgs): Either[String, PeriodicDueItemsArgs] =
    old.recipients
      .traverse(MailAddress.parse)
      .flatMap(l => NonEmptyList.fromList(l).toRight("No recipients provided"))
      .map { rec =>
        PeriodicDueItemsArgs(
          old.account,
          Right(Channel.Mail(Ident.unsafe(""), old.smtpConnection, rec)),
          old.remindDays,
          old.daysBack,
          old.tagsInclude,
          old.tagsExclude,
          old.itemDetailUrl
        )
      }

  def mkTransactor(ctx: Context): Transactor[IO] = {
    val xa = Transactor.fromConnection[IO](ctx.getConnection())
    Transactor.strategy.set(xa, Strategy.void) // transactions are handled by flyway
  }

}
