/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.updatecheck

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.scheduler.Context
import docspell.scheduler.Task
import docspell.store.records.RPeriodicTask
import docspell.store.records.RUserEmail
import docspell.store.usertask.UserTask
import docspell.store.usertask.UserTaskScope

import emil._

object UpdateCheckTask {
  val taskName: Ident = Ident.unsafe("new-release-check")

  type Args = Unit

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling update-check task"))

  def periodicTask[F[_]: Sync](cfg: UpdateCheckConfig): F[RPeriodicTask] =
    UserTask(
      Ident.unsafe("docspell-update-check"),
      taskName,
      cfg.enabled,
      cfg.schedule,
      None,
      ()
    ).encode.toPeriodicTask(
      UserTaskScope(cfg.senderAccount.collective),
      "Docspell Update Check".some
    )

  def apply[F[_]: Async](
      cfg: UpdateCheckConfig,
      sendCfg: MailSendConfig,
      emil: Emil[F],
      updateCheck: UpdateCheck[F],
      thisVersion: ThisVersion
  ): Task[F, Args, Unit] =
    if (cfg.enabled)
      Task { ctx =>
        for {
          _ <- ctx.logger.info(
            s"Check for updates. Current version is: ${thisVersion.get}"
          )
          _ <- ctx.logger.debug(
            s"Get SMTP connection for ${cfg.senderAccount.asString} and ${cfg.smtpId}"
          )
          smtpCfg <- findConnection(ctx, cfg)
          _ <- ctx.logger.debug("Checking for latest release at GitHub")
          latest <- updateCheck.latestRelease
          _ <- ctx.logger.debug(s"Got latest release: $latest.")
          _ <-
            if (cfg.testRun)
              ctx.logger.info(
                s"This is a test-run as configured. A mail will always be sent!"
              )
            else ().pure[F]
          _ <-
            if (latest.matchesVersion(thisVersion) && !cfg.testRun)
              ctx.logger.info(
                s"Latest release is ${latest.version}, which is the current one. Everything uptodate."
              )
            else
              ctx.logger.info(
                s"Sending mail about new release: ${latest.tag_name}"
              ) *> emil(smtpCfg.toMailConfig).send(
                MakeMail(sendCfg, cfg, smtpCfg, latest, thisVersion)
              )
        } yield ()
      }
    else
      Task.pure(())

  def findConnection[F[_]: Sync](
      ctx: Context[F, _],
      cfg: UpdateCheckConfig
  ): F[RUserEmail] =
    OptionT(ctx.store.transact(RUserEmail.getByName(cfg.senderAccount, cfg.smtpId)))
      .getOrElseF(
        Sync[F].raiseError(
          new Exception(
            s"No smtp connection found for user ${cfg.senderAccount.asString} and connection '${cfg.smtpId.id}'!"
          )
        )
      )

}
