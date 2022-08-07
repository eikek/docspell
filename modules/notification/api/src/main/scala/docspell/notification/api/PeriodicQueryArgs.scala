/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.data.NonEmptyList

import docspell.common._

import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

final case class PeriodicQueryArgs(
    account: AccountInfo,
    channels: NonEmptyList[ChannelRef],
    query: Option[ItemQueryString],
    bookmark: Option[String],
    baseUrl: Option[LenientUri],
    contentStart: Option[String]
) extends TaskArguments

object PeriodicQueryArgs {
  val taskName = Ident.unsafe("periodic-query-notify2")

  implicit val jsonDecoder: Decoder[PeriodicQueryArgs] =
    semiauto.deriveDecoder

  implicit def jsonEncoder: Encoder[PeriodicQueryArgs] =
    semiauto.deriveEncoder
}
