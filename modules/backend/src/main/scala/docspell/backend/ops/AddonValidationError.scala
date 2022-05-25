/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import docspell.common.{Ident, LenientUri}
import docspell.store.records.RAddonArchive

import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

sealed trait AddonValidationError {
  def cast: AddonValidationError = this

  def toLeft[A]: Either[AddonValidationError, A] = Left(this)
}

object AddonValidationError {

  implicit private val throwableDecoder: Decoder[Throwable] =
    Decoder.decodeString.map(new Exception(_))
  implicit private val throwableEncoder: Encoder[Throwable] =
    Encoder.encodeString.contramap(_.getMessage)

  case object AddonsDisabled extends AddonValidationError {}

  case class UrlUntrusted(url: LenientUri) extends AddonValidationError
  object UrlUntrusted {
    implicit val jsonDecoder: Decoder[UrlUntrusted] = deriveDecoder
    implicit val jsonEncoder: Encoder[UrlUntrusted] = deriveEncoder
  }

  case class NotAnAddon(error: Throwable) extends AddonValidationError
  object NotAnAddon {
    implicit val jsonDecoder: Decoder[NotAnAddon] = deriveDecoder
    implicit val jsonEncoder: Encoder[NotAnAddon] = deriveEncoder
  }

  case class AddonUnsupported(message: String, affectedNodes: List[Ident])
      extends AddonValidationError
  object AddonUnsupported {
    implicit val jsonDecoder: Decoder[AddonUnsupported] = deriveDecoder
    implicit val jsonEncoder: Encoder[AddonUnsupported] = deriveEncoder
  }

  case class InvalidAddon(message: String) extends AddonValidationError
  object InvalidAddon {
    implicit val jsonDecoder: Decoder[InvalidAddon] = deriveDecoder
    implicit val jsonEncoder: Encoder[InvalidAddon] = deriveEncoder
  }

  case class AddonExists(message: String, addon: RAddonArchive)
      extends AddonValidationError
  object AddonExists {
    def apply(addon: RAddonArchive): AddonExists =
      AddonExists(s"An addon '${addon.name}/${addon.version}' already exists!", addon)

    implicit val jsonDecoder: Decoder[AddonExists] = deriveDecoder
    implicit val jsonEncoder: Encoder[AddonExists] = deriveEncoder
  }

  case object AddonNotFound extends AddonValidationError

  case class DownloadFailed(error: Throwable) extends AddonValidationError
  object DownloadFailed {
    implicit val jsonDecoder: Decoder[DownloadFailed] = deriveDecoder
    implicit val jsonEncoder: Encoder[DownloadFailed] = deriveEncoder
  }

  case object ImpureAddonsDisabled extends AddonValidationError

  case object RefreshLocalAddon extends AddonValidationError

  implicit val jsonConfig: Configuration =
    Configuration.default.withKebabCaseConstructorNames
      .withDiscriminator("errorType")

  implicit val jsonDecoder: Decoder[AddonValidationError] = deriveConfiguredDecoder
  implicit val jsonEncoder: Encoder[AddonValidationError] = deriveConfiguredEncoder
}
