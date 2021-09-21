/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.data.Validated
import cats.data.ValidatedNec
import cats.implicits._

import docspell.common.config.Implicits._
import docspell.joex.scheduler.CountingScheme

import emil.MailAddress
import emil.javamail.syntax._
import pureconfig._
import pureconfig.generic.auto._
import yamusca.imports._

object ConfigFile {
  import Implicits._

  def loadConfig: Config =
    validOrThrow(ConfigSource.default.at("docspell.joex").loadOrThrow[Config])

  private def validOrThrow(cfg: Config): Config =
    validate(cfg).fold(err => sys.error(err.toList.mkString("- ", "\n", "")), identity)

  object Implicits {
    implicit val countingSchemeReader: ConfigReader[CountingScheme] =
      ConfigReader[String].emap(reason(CountingScheme.readString))

    implicit val templateReader: ConfigReader[Template] =
      ConfigReader[String].emap(reason(str => mustache.parse(str.trim).left.map(_._2)))

    implicit val mailAddressReader: ConfigReader[MailAddress] =
      ConfigReader[String].emap(reason(MailAddress.parse))
  }

  def validate(cfg: Config): ValidatedNec[String, Config] =
    List(
      failWhen(
        cfg.updateCheck.enabled && cfg.updateCheck.recipients.isEmpty,
        "No recipients given for enabled update check!"
      ),
      failWhen(
        cfg.updateCheck.enabled && cfg.updateCheck.smtpId.isEmpty,
        "No recipients given for enabled update check!"
      ),
      failWhen(
        cfg.updateCheck.enabled && cfg.updateCheck.subject.els.isEmpty,
        "No subject given for enabled update check!"
      )
    ).reduce(_ |+| _).map(_ => cfg)

  def failWhen(cond: Boolean, msg: => String): ValidatedNec[String, Unit] =
    Validated.condNec(!cond, (), msg)

}
