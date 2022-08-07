/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.implicits._

import io.circe.syntax._
import io.circe.{Decoder, DecodingFailure, Encoder}

sealed trait FileKeyPart {}

object FileKeyPart {

  case object Empty extends FileKeyPart

  final case class Collective(collective: CollectiveId) extends FileKeyPart

  final case class Category(collective: CollectiveId, category: FileCategory)
      extends FileKeyPart

  final case class Key(key: FileKey) extends FileKeyPart

  implicit val jsonEncoder: Encoder[FileKeyPart] =
    Encoder.instance {
      case Empty => ().asJson
      case Collective(cid) =>
        Map("collective" -> cid.asJson).asJson
      case Category(cid, cat) =>
        Map("collective" -> cid.asJson, "category" -> cat.asJson).asJson
      case Key(key) =>
        key.asJson
    }

  implicit val jsonDecoder: Decoder[FileKeyPart] =
    Decoder.instance { cursor =>
      for {
        cid <- cursor.getOrElse[Option[CollectiveId]]("collective")(None)
        cat <- cursor.getOrElse[Option[FileCategory]]("category")(None)
        emptyObj = cursor.keys.exists(_.isEmpty)

        c3 = cursor.as[FileKey].map(Key).toOption
        c2 = (cid, cat).mapN(Category)
        c1 = cid.map(Collective)
        c0 = Option.when(emptyObj)(Empty)

        c = c3.orElse(c2).orElse(c1).orElse(c0)
        res <- c.toRight(DecodingFailure("", cursor.history))
      } yield res
    }
}
