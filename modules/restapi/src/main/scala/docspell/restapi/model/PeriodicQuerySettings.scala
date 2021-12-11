/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.model

import docspell.common._
import docspell.query.ItemQuery
import docspell.restapi.codec.ItemQueryJson._

import com.github.eikek.calev.CalEvent
import com.github.eikek.calev.circe.CalevCirceCodec._
import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

// this must comply to the definition in openapi.yml in `extraSchemas`
final case class PeriodicQuerySettings(
    id: Ident,
    summary: Option[String],
    enabled: Boolean,
    channel: NotificationChannel,
    query: ItemQuery,
    schedule: CalEvent
) {}

object PeriodicQuerySettings {

  implicit val jsonDecoder: Decoder[PeriodicQuerySettings] =
    semiauto.deriveDecoder

  implicit val jsonEncoder: Encoder[PeriodicQuerySettings] =
    semiauto.deriveEncoder
}
