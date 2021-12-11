/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.model

import docspell.common._
import docspell.restapi.model._

import com.github.eikek.calev.CalEvent
import com.github.eikek.calev.circe.CalevCirceCodec._
import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

// this must comply to the definition in openapi.yml in `extraSchemas`
final case class PeriodicDueItemsSettings(
    id: Ident,
    enabled: Boolean,
    summary: Option[String],
    channel: NotificationChannel,
    schedule: CalEvent,
    remindDays: Int,
    capOverdue: Boolean,
    tagsInclude: List[Tag],
    tagsExclude: List[Tag]
)
object PeriodicDueItemsSettings {

  implicit val jsonDecoder: Decoder[PeriodicDueItemsSettings] =
    semiauto.deriveDecoder[PeriodicDueItemsSettings]
  implicit val jsonEncoder: Encoder[PeriodicDueItemsSettings] =
    semiauto.deriveEncoder[PeriodicDueItemsSettings]
}
