package docspell.ftssolr

import docspell.common._
import docspell.ftsclient._
import io.circe._
import Fields.{Item, Attachment}

trait JsonCodec {

  implicit def attachmentEncoder: Encoder[TextData.Attachment] =
    new Encoder[TextData.Attachment] {
      final def apply(td: TextData.Attachment): Json = Json.obj(
        (Fields.id, Ident.encodeIdent(td.id)),
        (Fields.itemId, Ident.encodeIdent(td.item)),
        (Fields.collectiveId, Ident.encodeIdent(td.collective)),
        (Attachment.attachmentId, Ident.encodeIdent(td.attachId)),
        (Attachment.attachmentName, Json.fromString(td.name.getOrElse(""))),
        (Attachment.content, Json.fromString(td.text.getOrElse(""))),
        (Fields.discriminator, Json.fromString("attachment"))
      )
    }

  implicit def itemEncoder: Encoder[TextData.Item] =
    new Encoder[TextData.Item] {
      final def apply(td: TextData.Item): Json = Json.obj(
        (Fields.id, Ident.encodeIdent(td.id)),
        (Fields.itemId, Ident.encodeIdent(td.item)),
        (Fields.collectiveId, Ident.encodeIdent(td.collective)),
        (Item.itemName, Json.fromString(td.name.getOrElse(""))),
        (Item.itemNotes, Json.fromString(td.notes.getOrElse(""))),
        (Fields.discriminator, Json.fromString("item"))
      )
    }


  implicit def textDataEncoder(implicit
      ae: Encoder[TextData.Attachment],
      ie: Encoder[TextData.Item]
  ): Encoder[TextData] =
    Encoder(_.fold(ae.apply, ie.apply))
}

object JsonCodec extends JsonCodec
