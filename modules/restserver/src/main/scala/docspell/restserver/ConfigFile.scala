/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.Semigroup
import cats.data.{Validated, ValidatedNec}
import cats.implicits._

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common.config.Implicits._
import docspell.oidc.{ProviderConfig, SignatureAlgo}
import docspell.restserver.auth.OpenId

import pureconfig._
import pureconfig.generic.auto._

object ConfigFile {
  import Implicits._

  def loadConfig: Config =
    Validate(ConfigSource.default.at("docspell.server").loadOrThrow[Config])

  object Implicits {
    implicit val signupModeReader: ConfigReader[SignupConfig.Mode] =
      ConfigReader[String].emap(reason(SignupConfig.Mode.fromString))

    implicit val sigAlgoReader: ConfigReader[SignatureAlgo] =
      ConfigReader[String].emap(reason(SignatureAlgo.fromString))

    implicit val openIdExtractorReader: ConfigReader[OpenId.UserInfo.Extractor] =
      ConfigReader[String].emap(reason(OpenId.UserInfo.Extractor.fromString))
  }

  object Validate {

    implicit val firstConfigSemigroup: Semigroup[Config] =
      Semigroup.first

    def apply(config: Config): Config =
      all(config).foldLeft(valid(config))(_.combine(_)) match {
        case Validated.Valid(cfg) => cfg
        case Validated.Invalid(errs) =>
          val msg = errs.toList.mkString("- ", "\n- ", "\n")
          throw sys.error(s"\n\n$msg")
      }

    def all(cfg: Config) = List(
      duplicateOpenIdProvider(cfg),
      signKeyVsUserUrl(cfg)
    )

    private def valid(cfg: Config): ValidatedNec[String, Config] =
      Validated.validNec(cfg)

    def duplicateOpenIdProvider(cfg: Config): ValidatedNec[String, Config] = {
      val dupes =
        cfg.openid
          .filter(_.enabled)
          .groupBy(_.provider.providerId)
          .filter(_._2.size > 1)
          .map(_._1.id)
          .toList

      val dupesStr = dupes.mkString(", ")
      if (dupes.isEmpty) valid(cfg)
      else Validated.invalidNec(s"There is a duplicate openId provider: $dupesStr")
    }

    def signKeyVsUserUrl(cfg: Config): ValidatedNec[String, Config] = {
      def checkProvider(p: ProviderConfig): ValidatedNec[String, Config] =
        if (p.signKey.isEmpty && p.userUrl.isEmpty)
          Validated.invalidNec(
            s"Either user-url or sign-key must be set for provider ${p.providerId.id}"
          )
        else if (p.signKey.nonEmpty && p.scope.isEmpty)
          Validated.invalidNec(
            s"A scope is missing for OIDC auth at provider ${p.providerId.id}"
          )
        else Validated.valid(cfg)

      cfg.openid
        .filter(_.enabled)
        .map(_.provider)
        .map(checkProvider)
        .foldLeft(valid(cfg))(_.combine(_))
    }
  }
}
