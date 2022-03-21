/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex

import cats.effect.Async

import docspell.config.Implicits._
import docspell.config.{ConfigFactory, FtsType, Validation}
import docspell.scheduler.CountingScheme

import emil.MailAddress
import emil.javamail.syntax._
import pureconfig._
import pureconfig.generic.auto._
import yamusca.imports._

object ConfigFile {
  // IntelliJ is wrong, this is required
  import Implicits._

  def loadConfig[F[_]: Async](args: List[String]): F[Config] = {
    val logger = docspell.logging.getLogger[F]
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
      ),
      Validation(cfg => cfg.files.validate.map(_ => cfg)),
      Validation.failWhen(
        cfg =>
          cfg.fullTextSearch.enabled &&
            cfg.fullTextSearch.backend == FtsType.PostgreSQL &&
            cfg.fullTextSearch.postgresql.useDefaultConnection &&
            !cfg.jdbc.dbmsName.contains("postgresql"),
        s"PostgreSQL defined fulltext search backend with default-connection, which is not a PostgreSQL connection!"
      )
    )
}
