/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect.Async

import docspell.common.Logger
import docspell.config.Implicits._
import docspell.config.{ConfigFactory, Validation}
import docspell.joex.scheduler.CountingScheme

import emil.MailAddress
import emil.javamail.syntax._
import pureconfig._
import pureconfig.generic.auto._
import yamusca.imports._

object ConfigFile {
  import Implicits._

  def loadConfig[F[_]: Async](args: List[String]): F[Config] = {
    val logger = Logger.log4s[F](org.log4s.getLogger)
    ConfigFactory
      .default[F, Config](logger, "docspell.joex")(args, validate)
  }

  object Implicits {
    implicit val countingSchemeReader: ConfigReader[CountingScheme] =
      ConfigReader[String].emap(reason(CountingScheme.readString))

    implicit val templateReader: ConfigReader[Template] =
      ConfigReader[String].emap(reason(str => mustache.parse(str.trim).left.map(_._2)))

    implicit val mailAddressReader: ConfigReader[MailAddress] =
      ConfigReader[String].emap(reason(MailAddress.parse))
  }

  def validate: Validation[Config] =
    Validation.of[Config](
      Validation.failWhen(
        cfg => cfg.updateCheck.enabled && cfg.updateCheck.recipients.isEmpty,
        "No recipients given for enabled update check!"
      ),
      Validation.failWhen(
        cfg => cfg.updateCheck.enabled && cfg.updateCheck.smtpId.isEmpty,
        "No recipients given for enabled update check!"
      ),
      Validation.failWhen(
        cfg => cfg.updateCheck.enabled && cfg.updateCheck.subject.els.isEmpty,
        "No subject given for enabled update check!"
      )
    )
}
