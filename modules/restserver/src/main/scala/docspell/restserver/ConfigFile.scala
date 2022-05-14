/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import java.security.SecureRandom

import cats.Monoid
import cats.effect.Async

import docspell.backend.signup.{Config => SignupConfig}
import docspell.config.Implicits._
import docspell.config.{ConfigFactory, FtsType, Validation}
import docspell.oidc.{ProviderConfig, SignatureAlgo}
import docspell.restserver.auth.OpenId

import pureconfig._
import pureconfig.generic.auto._
import scodec.bits.ByteVector

object ConfigFile {
  private[this] val unsafeLogger = docspell.logging.unsafeLogger

  // IntelliJ is wrong, this is required
  import Implicits._

  def loadConfig[F[_]: Async](args: List[String]): F[Config] = {
    val logger = docspell.logging.getLogger[F]
    val validate =
      Validation.of(
        generateSecretIfEmpty,
        duplicateOpenIdProvider,
        signKeyVsUserUrl,
        filesValidate
      )
    ConfigFactory
      .default[F, Config](logger, "docspell.server")(args, validate)
  }

  object Implicits {
    implicit val signupModeReader: ConfigReader[SignupConfig.Mode] =
      ConfigReader[String].emap(reason(SignupConfig.Mode.fromString))

    implicit val sigAlgoReader: ConfigReader[SignatureAlgo] =
      ConfigReader[String].emap(reason(SignatureAlgo.fromString))

    implicit val openIdExtractorReader: ConfigReader[OpenId.UserInfo.Extractor] =
      ConfigReader[String].emap(reason(OpenId.UserInfo.Extractor.fromString))
  }

  def generateSecretIfEmpty: Validation[Config] =
    Validation { cfg =>
      if (cfg.auth.serverSecret.isEmpty) {
        unsafeLogger.warn(
          "No serverSecret specified. Generating a random one. It is recommended to add a server-secret in the config file."
        )
        val random = new SecureRandom
        val buffer = new Array[Byte](32)
        random.nextBytes(buffer)
        val secret = ByteVector.view(buffer)
        Validation.valid(cfg.copy(auth = cfg.auth.copy(serverSecret = secret)))
      } else Validation.valid(cfg)
    }

  def duplicateOpenIdProvider: Validation[Config] =
    Validation { cfg =>
      val dupes =
        cfg.openid
          .filter(_.enabled)
          .groupBy(_.provider.providerId)
          .filter(_._2.size > 1)
          .map(_._1.id)
          .toList

      val dupesStr = dupes.mkString(", ")
      if (dupes.isEmpty) Validation.valid(cfg)
      else Validation.invalid(s"There is a duplicate openId provider: $dupesStr")
    }

  def signKeyVsUserUrl: Validation[Config] =
    Validation.flatten { cfg =>
      def checkProvider(p: ProviderConfig): Validation[Config] =
        Validation { _ =>
          if (p.signKey.isEmpty && p.userUrl.isEmpty)
            Validation.invalid(
              s"Either user-url or sign-key must be set for provider ${p.providerId.id}"
            )
          else if (p.signKey.nonEmpty && p.scope.isEmpty)
            Validation.invalid(
              s"A scope is missing for OIDC auth at provider ${p.providerId.id}"
            )
          else Validation.valid(cfg)
        }

      Monoid[Validation[Config]]
        .combineAll(
          cfg.openid
            .filter(_.enabled)
            .map(_.provider)
            .map(checkProvider)
        )
    }

  def filesValidate: Validation[Config] =
    Validation(cfg => cfg.backend.files.validate.map(_ => cfg))

  def postgresFtsValidate: Validation[Config] =
    Validation.failWhen(
      cfg =>
        cfg.fullTextSearch.enabled &&
          cfg.fullTextSearch.backend == FtsType.PostgreSQL &&
          cfg.fullTextSearch.postgresql.useDefaultConnection &&
          !cfg.backend.jdbc.dbmsName.contains("postgresql"),
      s"PostgreSQL defined fulltext search backend with default-connection, which is not a PostgreSQL connection!"
    )

}
