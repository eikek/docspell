package docspell.ftssolr

import docspell.common._
import docspell.ftsclient._
import io.circe._

trait JsonCodec {

  implicit def attachmentEncoder: Encoder[TextData.Attachment] =
    new Encoder[TextData.Attachment] {
      final def apply(td: TextData.Attachment): Json = Json.obj(
        ("id", Ident.encodeIdent(td.id)),
        ("item", Ident.encodeIdent(td.item)),
        ("collective", Ident.encodeIdent(td.collective)),
        ("attachmentName", Json.fromString(td.name.getOrElse(""))),
        ("content", Json.fromString(td.text.getOrElse(""))),
        ("discriminator", Json.fromString("attachment"))
      )
    }

  implicit def itemEncoder: Encoder[TextData.Item] =
    new Encoder[TextData.Item] {
      final def apply(td: TextData.Item): Json = Json.obj(
        ("id", Ident.encodeIdent(td.id)),
        ("item", Ident.encodeIdent(td.item)),
        ("collective", Ident.encodeIdent(td.collective)),
        ("itemName", Json.fromString(td.name.getOrElse(""))),
        ("itemNotes", Json.fromString(td.notes.getOrElse(""))),
        ("discriminator", Json.fromString("item"))
      )
    }


  implicit def textDataEncoder(implicit
      ae: Encoder[TextData.Attachment],
      ie: Encoder[TextData.Item]
  ): Encoder[TextData] =
    Encoder(_.fold(ae.apply, ie.apply))
}

object JsonCodec extends JsonCodec
