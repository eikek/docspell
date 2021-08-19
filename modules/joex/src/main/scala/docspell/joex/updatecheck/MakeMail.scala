/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.updatecheck

import cats.effect._

import docspell.common.MailSendConfig
import docspell.joex.mail.EmilHeader
import docspell.store.records.RUserEmail

import emil._
import emil.builder._
import emil.markdown._
import yamusca.implicits._
import yamusca.imports._

object MakeMail {

  def apply[F[_]: Sync](
      sendCfg: MailSendConfig,
      cfg: UpdateCheckConfig,
      smtpCfg: RUserEmail,
      latestRelease: UpdateCheck.Release
  ): Mail[F] = {

    val templateCtx = TemplateCtx(latestRelease)
    val md          = templateCtx.render(cfg.body)
    val subj        = templateCtx.render(cfg.subject)

    MailBuilder.build(
      From(smtpCfg.mailFrom),
      Tos(cfg.recipients),
      XMailer.emil,
      Subject(subj),
      EmilHeader.listId(sendCfg.listId),
      MarkdownBody[F](md).withConfig(
        MarkdownConfig("body { font-size: 10pt; font-family: sans-serif; }")
      )
    )
  }

  final case class TemplateCtx(
      currentVersion: String,
      latestVersion: String,
      releasedAt: String
  )
  object TemplateCtx {
    def apply(release: UpdateCheck.Release): TemplateCtx =
      TemplateCtx(UpdateCheck.currentVersion, release.version, release.published_at)

    implicit val yamuscaConverter: ValueConverter[TemplateCtx] =
      ValueConverter.deriveConverter[TemplateCtx]
  }
}
