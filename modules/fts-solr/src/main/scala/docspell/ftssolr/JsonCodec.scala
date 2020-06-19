package docspell.ftssolr

//import cats.implicits._
import io.circe._
import docspell.common._
import docspell.ftsclient._

trait JsonCodec {

  implicit def attachmentEncoder(implicit
      enc: Encoder[Ident]
  ): Encoder[TextData.Attachment] =
    new Encoder[TextData.Attachment] {
      final def apply(td: TextData.Attachment): Json =
        Json.obj(
          (Field.id.name, enc(td.id)),
          (Field.itemId.name, enc(td.item)),
          (Field.collectiveId.name, enc(td.collective)),
          (Field.attachmentId.name, enc(td.attachId)),
          (Field.attachmentName.name, Json.fromString(td.name.getOrElse(""))),
          (Field.content.name, Json.fromString(td.text.getOrElse(""))),
          (Field.discriminator.name, Json.fromString("attachment"))
        )
    }

  implicit def itemEncoder(implicit enc: Encoder[Ident]): Encoder[TextData.Item] =
    new Encoder[TextData.Item] {
      final def apply(td: TextData.Item): Json =
        Json.obj(
          (Field.id.name, enc(td.id)),
          (Field.itemId.name, enc(td.item)),
          (Field.collectiveId.name, enc(td.collective)),
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

  implicit def ftsResultDecoder: Decoder[FtsResult] =
    new Decoder[FtsResult] {
      final def apply(c: HCursor): Decoder.Result[FtsResult] =
        for {
          qtime    <- c.downField("responseHeader").get[Duration]("QTime")
          count    <- c.downField("response").get[Int]("numFound")
          maxScore <- c.downField("response").get[Double]("maxScore")
          results  <- c.downField("response").get[List[FtsResult.ItemMatch]]("docs")
          highligh <- c.get[Map[Ident, Map[String, List[String]]]]("highlighting")
          highline = highligh.map(kv => kv._1 -> kv._2.values.flatten.toList)
        } yield FtsResult(qtime, count, maxScore, highline, results)
    }

  implicit def decodeItemMatch: Decoder[FtsResult.ItemMatch] =
    new Decoder[FtsResult.ItemMatch] {
      final def apply(c: HCursor): Decoder.Result[FtsResult.ItemMatch] =
        for {
          itemId <- c.get[Ident]("itemId")
          id     <- c.get[Ident]("id")
          coll   <- c.get[Ident]("collectiveId")
          score  <- c.get[Double]("score")
          md     <- decodeMatchData(c)
        } yield FtsResult.ItemMatch(id, itemId, coll, score, md)
    }

  def decodeMatchData: Decoder[FtsResult.MatchData] =
    new Decoder[FtsResult.MatchData] {
      final def apply(c: HCursor): Decoder.Result[FtsResult.MatchData] =
        for {
          disc <- c.get[String]("discriminator")
          md <-
            if ("attachment" == disc)
              c.get[Ident]("attachmentId").map(FtsResult.AttachmentData.apply)
            else Right(FtsResult.ItemData)
        } yield md
    }

  implicit def identKeyEncoder: KeyEncoder[Ident] =
    new KeyEncoder[Ident] {
      override def apply(ident: Ident): String = ident.id
    }
  implicit def identKeyDecoder: KeyDecoder[Ident] =
    new KeyDecoder[Ident] {
      override def apply(ident: String): Option[Ident] = Ident(ident).toOption
    }
}

object JsonCodec extends JsonCodec
