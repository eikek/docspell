package docspell.ftssolr

import cats.effect._
import org.http4s._
import cats.implicits._
import org.http4s.client.Client
import org.http4s.circe._
import org.http4s.client.dsl.Http4sClientDsl
import org.log4s.getLogger
import _root_.io.circe.syntax._
import _root_.io.circe._
import _root_.io.circe.generic.semiauto._

import Fields.{Attachment, Item}

trait SolrSetup[F[_]] {

  def setupSchema: F[Unit]

}

object SolrSetup {
  private[this] val logger = getLogger

  def apply[F[_]: ConcurrentEffect](cfg: SolrConfig, client: Client[F]): SolrSetup[F] = {
    val dsl = new Http4sClientDsl[F] {}
    import dsl._

    new SolrSetup[F] {
      val url = (Uri.unsafeFromString(cfg.url.asString) / "schema")
        .withQueryParam("commitWithin", cfg.commitWithin.toString)

      def setupSchema: F[Unit] = {
        val cmds0 =
          List(
            Fields.id,
            Fields.itemId,
            Fields.collectiveId,
            Fields.discriminator,
            Attachment.attachmentId
          )
            .traverse(addStringField)
        val cmds1 = List(
          Attachment.attachmentName,
          Attachment.content,
          Item.itemName,
          Item.itemNotes
        )
          .traverse(addTextField)

        cmds0 *> cmds1 *> ().pure[F]
      }

      private def run(cmd: Json): F[Unit] = {
        val req = Method.POST(cmd, url)
        logger.debug(s"Running request $req: ${cmd.noSpaces}")
        client.expect[String](req).map(r => logger.debug(s"Response: $r"))
      }

      private def addStringField(name: String): F[Unit] =
        run(DeleteField.command(DeleteField(name))).attempt *>
          run(AddField.command(AddField.string(name)))

      private def addTextField(name: String): F[Unit] =
        run(DeleteField.command(DeleteField(name))).attempt *>
          run(AddField.command(AddField.text(name)))

    }
  }

  // Schema Commands

  case class AddField(
      name: String,
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

    def string(name: String): AddField =
      AddField(name, "string", true, true, false)

    def text(name: String): AddField =
      AddField(name, "text_general", true, true, false)
  }

  case class DeleteField(name: String)
  object DeleteField {
    implicit val encoder: Encoder[DeleteField] =
      deriveEncoder[DeleteField]

    def command(body: DeleteField): Json =
      Map("delete-field" -> body.asJson).asJson
  }
}
