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
import docspell.scheduler.Task
import docspell.scheduler.usertask.UserTask
import docspell.store.Store
import docspell.store.records.{RUser, RUserEmail}

import emil._

object UpdateCheckTask {
  val taskName: Ident = Ident.unsafe("new-release-check")

  type Args = Unit

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling update-check task"))

  def periodicTask[F[_]: Sync](cfg: UpdateCheckConfig): F[UserTask[Unit]] =
    UserTask(
      Ident.unsafe("docspell-update-check"),
      taskName,
      cfg.enabled,
      cfg.schedule,
      "Docspell Update Check".some,
      ()
    ).pure[F]

  def apply[F[_]: Async](
      cfg: UpdateCheckConfig,
      sendCfg: MailSendConfig,
      store: Store[F],
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
          smtpCfg <- findConnection(store, cfg)
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
      store: Store[F],
      cfg: UpdateCheckConfig
  ): F[RUserEmail] =
    OptionT(store.transact(RUser.findByAccount(cfg.senderAccount)))
      .map(_.uid)
      .flatMap(uid => OptionT(store.transact(RUserEmail.getByName(uid, cfg.smtpId))))
      .getOrElseF(
        Sync[F].raiseError(
          new Exception(
            s"No smtp connection found for user ${cfg.senderAccount.asString} and connection '${cfg.smtpId.id}'!"
          )
        )
      )

}
