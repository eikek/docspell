/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr

import cats.implicits._

import docspell.common._
import docspell.ftsclient._

import io.circe._
import io.circe.syntax._

trait JsonCodec {

  implicit def attachmentEncoder(implicit
      enc: Encoder[Ident]
  ): Encoder[TextData.Attachment] =
    new Encoder[TextData.Attachment] {
      final def apply(td: TextData.Attachment): Json = {
        val cnt =
          (Field.contentField(td.lang).name, Json.fromString(td.text.getOrElse("")))

        Json.fromFields(
          cnt :: List(
            (Field.id.name, enc(td.id)),
            (Field.itemId.name, enc(td.item)),
            (Field.collectiveId.name, enc(td.collective)),
            (Field.folderId.name, td.folder.getOrElse(Ident.unsafe("")).asJson),
            (Field.attachmentId.name, enc(td.attachId)),
            (Field.attachmentName.name, Json.fromString(td.name.getOrElse(""))),
            (Field.discriminator.name, Json.fromString("attachment"))
          )
        )

      }
    }

  implicit def itemEncoder(implicit enc: Encoder[Ident]): Encoder[TextData.Item] =
    new Encoder[TextData.Item] {
      final def apply(td: TextData.Item): Json =
        Json.obj(
          (Field.id.name, enc(td.id)),
          (Field.itemId.name, enc(td.item)),
          (Field.collectiveId.name, enc(td.collective)),
          (Field.folderId.name, td.folder.getOrElse(Ident.unsafe("")).asJson),
          (Field.itemName.name, Json.fromString(td.name.getOrElse(""))),
          (Field.itemNotes.name, Json.fromString(td.notes.getOrElse(""))),
          (Field.discriminator.name, Json.fromString("item"))
        )
    }

  implicit def textDataEncoder(implicit
      ae: Encoder[TextData.Attachment],
      ie: Encoder[TextData.Item]
  ): Encoder[TextData] =
    Encoder(_.fold(ae.apply, ie.apply))

  implicit def versionDocEncoder: Encoder[VersionDoc] =
    new Encoder[VersionDoc] {
      final def apply(d: VersionDoc): Json =
        Json.fromFields(
          List(
            (VersionDoc.Fields.id.name, d.id.asJson),
            (
              VersionDoc.Fields.currentVersion.name,
              Map("set" -> d.currentVersion.asJson).asJson
            )
          )
        )
    }

  implicit def decoderVersionDoc: Decoder[VersionDoc] =
    new Decoder[VersionDoc] {
      final def apply(c: HCursor): Decoder.Result[VersionDoc] =
        for {
          id <- c.get[String](VersionDoc.Fields.id.name)
          version <- c.get[Int](VersionDoc.Fields.currentVersion.name)
        } yield VersionDoc(id, version)
    }

  implicit def versionDocDecoder: Decoder[Option[VersionDoc]] =
    new Decoder[Option[VersionDoc]] {
      final def apply(c: HCursor): Decoder.Result[Option[VersionDoc]] =
        c.downField("response")
          .get[List[VersionDoc]]("docs")
          .map(_.headOption)
    }

  implicit def docIdResultsDecoder: Decoder[DocIdResult] =
    new Decoder[DocIdResult] {
      final def apply(c: HCursor): Decoder.Result[DocIdResult] =
        c.downField("response")
          .downField("docs")
          .values
          .getOrElse(Nil)
          .toList
          .traverse(_.hcursor.get[Ident](Field.id.name))
          .map(DocIdResult.apply)
    }

  implicit def ftsResultDecoder: Decoder[FtsResult] =
    new Decoder[FtsResult] {
      final def apply(c: HCursor): Decoder.Result[FtsResult] =
        for {
          qtime <- c.downField("responseHeader").get[Duration]("QTime")
          count <- c.downField("response").get[Int]("numFound")
          maxScore <- c.downField("response").get[Double]("maxScore")
          results <- c.downField("response").get[List[FtsResult.ItemMatch]]("docs")
          highlightng <- c.get[Map[Ident, Map[String, List[String]]]]("highlighting")
          highlight = highlightng.map(kv => kv._1 -> kv._2.values.flatten.toList)
        } yield FtsResult(qtime, count, maxScore, highlight, results)
    }

  implicit def decodeItemMatch: Decoder[FtsResult.ItemMatch] =
    new Decoder[FtsResult.ItemMatch] {
      final def apply(c: HCursor): Decoder.Result[FtsResult.ItemMatch] =
        for {
          itemId <- c.get[Ident](Field.itemId.name)
          id <- c.get[Ident](Field.id.name)
          coll <- c.get[Ident](Field.collectiveId.name)
          score <- c.get[Double]("score")
          md <- decodeMatchData(c)
        } yield FtsResult.ItemMatch(id, itemId, coll, score, md)
    }

  def decodeMatchData: Decoder[FtsResult.MatchData] =
    new Decoder[FtsResult.MatchData] {
      final def apply(c: HCursor): Decoder.Result[FtsResult.MatchData] =
        for {
          disc <- c.get[String]("discriminator")
          md <-
            if ("attachment" == disc)
              for {
                aId <- c.get[Ident](Field.attachmentId.name)
                aName <- c.get[String](Field.attachmentName.name)
              } yield FtsResult.AttachmentData(aId, aName)
            else Right(FtsResult.ItemData)
        } yield md
    }

  implicit def decodeEverythingToUnit: Decoder[Unit] =
    new Decoder[Unit] {
      final def apply(c: HCursor): Decoder.Result[Unit] =
        Right(())
    }

  implicit def identKeyEncoder: KeyEncoder[Ident] =
    new KeyEncoder[Ident] {
      override def apply(ident: Ident): String = ident.id
    }
  implicit def identKeyDecoder: KeyDecoder[Ident] =
    new KeyDecoder[Ident] {
      override def apply(ident: String): Option[Ident] = Ident(ident).toOption
    }

  def setAttachmentEncoder(implicit
      enc: Encoder[Ident]
  ): Encoder[TextData.Attachment] =
    new Encoder[TextData.Attachment] {
      final def apply(td: TextData.Attachment): Json = {
        val setter = List(
          td.name.map(n => (Field.attachmentName.name, Map("set" -> n.asJson).asJson)),
          td.text.map(txt =>
            (Field.contentField(td.lang).name, Map("set" -> txt.asJson).asJson)
          )
        ).flatten
        Json.fromFields(
          (Field.id.name, enc(td.id)) :: setter
        )
      }
    }

  def setItemEncoder(implicit enc: Encoder[Ident]): Encoder[TextData.Item] =
    new Encoder[TextData.Item] {
      final def apply(td: TextData.Item): Json = {
        val setter = List(
          td.name.map(n => (Field.itemName.name, Map("set" -> n.asJson).asJson)),
          td.notes.map(n => (Field.itemNotes.name, Map("set" -> n.asJson).asJson))
        ).flatten

        Json.fromFields(
          (Field.id.name, enc(td.id)) :: setter
        )
      }
    }

  implicit def setTextDataFieldsEncoder: Encoder[SetFields] =
    Encoder(_.td.fold(setAttachmentEncoder.apply, setItemEncoder.apply))

  implicit def setFolderEncoder(implicit
      enc: Encoder[Option[Ident]]
  ): Encoder[SetFolder] =
    new Encoder[SetFolder] {
      final def apply(td: SetFolder): Json =
        Json.fromFields(
          List(
            (Field.id.name, td.docId.asJson),
            (
              Field.folderId.name,
              Map("set" -> td.folder.asJson).asJson
            )
          )
        )
    }
}

object JsonCodec extends JsonCodec
