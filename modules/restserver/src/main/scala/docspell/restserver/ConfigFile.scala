/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import java.security.SecureRandom

import cats.Semigroup
import cats.data.{Validated, ValidatedNec}
import cats.effect.Async
import cats.implicits._

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common.Logger
import docspell.config.ConfigFactory
import docspell.config.Implicits._
import docspell.oidc.{ProviderConfig, SignatureAlgo}
import docspell.restserver.auth.OpenId

import pureconfig._
import pureconfig.generic.auto._
import scodec.bits.ByteVector

object ConfigFile {
  private[this] val unsafeLogger = org.log4s.getLogger
  import Implicits._

  def loadConfig[F[_]: Async](args: List[String]): F[Config] = {
    val logger = Logger.log4s(unsafeLogger)
    ConfigFactory
      .default[F, Config](logger, "docspell.server")(args)
      .map(cfg => Validate(cfg))
  }

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
      signKeyVsUserUrl(cfg),
      generateSecretIfEmpty(cfg)
    )

    private def valid(cfg: Config): ValidatedNec[String, Config] =
      Validated.validNec(cfg)

    def generateSecretIfEmpty(cfg: Config): ValidatedNec[String, Config] =
      if (cfg.auth.serverSecret.isEmpty) {
        unsafeLogger.warn(
          "No serverSecret specified. Generating a random one. It is recommended to add a server-secret in the config file."
        )
        val random = new SecureRandom()
        val buffer = new Array[Byte](32)
        random.nextBytes(buffer)
        val secret = ByteVector.view(buffer)
        valid(cfg.copy(auth = cfg.auth.copy(serverSecret = secret)))
      } else valid(cfg)

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
