/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common.BaseJsonCodecs._
import docspell.common._

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

/** Information about an attachment file (can be attachment-source or attachment) */
case class AttachedFile(
    id: Ident,
    name: Option[String],
    position: Int,
    language: Option[Language],
    mimetype: MimeType,
    length: ByteSize,
    checksum: ByteVector
)

object AttachedFile {

  implicit val jsonDecoder: Decoder[AttachedFile] = deriveDecoder
  implicit val jsonEncoder: Encoder[AttachedFile] = deriveEncoder
}
