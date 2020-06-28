package docspell.ftssolr

import cats.effect._
import cats.implicits._

import docspell.common._

import _root_.io.circe._
import _root_.io.circe.generic.semiauto._
import _root_.io.circe.syntax._
import org.http4s._
import org.http4s.circe._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl

trait SolrSetup[F[_]] {

  def setupSchema: F[Unit]

}

object SolrSetup {

  def apply[F[_]: ConcurrentEffect](cfg: SolrConfig, client: Client[F]): SolrSetup[F] = {
    val dsl = new Http4sClientDsl[F] {}
    import dsl._

    new SolrSetup[F] {
      val url = (Uri.unsafeFromString(cfg.url.asString) / "schema")
        .withQueryParam("commitWithin", cfg.commitWithin.toString)

      def setupSchema: F[Unit] = {
        val cmds0 =
          List(
            Field.id,
            Field.itemId,
            Field.collectiveId,
            Field.discriminator,
            Field.attachmentId
          )
            .traverse(addStringField)
        val cmds1 = List(
          Field.attachmentName,
          Field.content,
          Field.itemName,
          Field.itemNotes
        )
          .traverse(addTextField(None))

        val cntLang = Language.all.traverse {
          case l @ Language.German =>
            addTextField(l.some)(Field.content_de)
          case l @ Language.English =>
            addTextField(l.some)(Field.content_en)
        }

        cmds0 *> cmds1 *> cntLang *> ().pure[F]
      }

      private def run(cmd: Json): F[Unit] = {
        val req = Method.POST(cmd, url)
        client.expect[Unit](req)
      }

      private def addStringField(field: Field): F[Unit] =
        run(DeleteField.command(DeleteField(field))).attempt *>
          run(AddField.command(AddField.string(field)))

      private def addTextField(lang: Option[Language])(field: Field): F[Unit] =
        lang match {
          case None =>
            run(DeleteField.command(DeleteField(field))).attempt *>
              run(AddField.command(AddField.text(field)))
          case Some(Language.German) =>
            run(DeleteField.command(DeleteField(field))).attempt *>
              run(AddField.command(AddField.textDE(field)))
          case Some(Language.English) =>
            run(DeleteField.command(DeleteField(field))).attempt *>
              run(AddField.command(AddField.textEN(field)))
        }
    }
  }

  // Schema Commands: The structure is for conveniently creating the
  // solr json. All fields must be stored, because of highlighting and
  // single-updates only work when all fields are stored.

  case class AddField(
      name: Field,
      `type`: String,
      stored: Boolean,
      indexed: Boolean,
      multiValued: Boolean
  )
  object AddField {
    implicit val encoder: Encoder[AddField] =
      deriveEncoder[AddField]

    def command(body: AddField): Json =
      Map("add-field" -> body.asJson).asJson

    def string(field: Field): AddField =
      AddField(field, "string", true, true, false)

    def text(field: Field): AddField =
      AddField(field, "text_general", true, true, false)

    def textDE(field: Field): AddField =
      AddField(field, "text_de", true, true, false)

    def textEN(field: Field): AddField =
      AddField(field, "text_en", true, true, false)
  }

  case class DeleteField(name: Field)
  object DeleteField {
    implicit val encoder: Encoder[DeleteField] =
      deriveEncoder[DeleteField]

    def command(body: DeleteField): Json =
      Map("delete-field" -> body.asJson).asJson
  }
}
