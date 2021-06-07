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

  def setupSchema: List[SolrMigration[F]]

  def remainingSetup: F[List[SolrMigration[F]]]

}

object SolrSetup {
  private val versionDocId = "6d8f09f4-8d7e-4bc9-98b8-7c89223b36dd"

  def apply[F[_]: ConcurrentEffect](cfg: SolrConfig, client: Client[F]): SolrSetup[F] = {
    val dsl = new Http4sClientDsl[F] {}
    import dsl._

    new SolrSetup[F] {

      val url = (Uri.unsafeFromString(cfg.url.asString) / "schema")
        .withQueryParam("commitWithin", cfg.commitWithin.toString)

      def remainingSetup: F[List[SolrMigration[F]]] =
        for {
          current <- SolrQuery(cfg, client).findVersionDoc(versionDocId)
          migs = current match {
            case None => setupSchema
            case Some(ver) =>
              val verDoc =
                VersionDoc(versionDocId, allMigrations.map(_.value.version).max)
              val solrUp = SolrUpdate(cfg, client)
              val remain = allMigrations.filter(v => v.value.version > ver.currentVersion)
              if (remain.isEmpty) remain
              else remain :+ SolrMigration.writeVersion(solrUp, verDoc)
          }
        } yield migs

      def setupSchema: List[SolrMigration[F]] = {
        val verDoc = VersionDoc(versionDocId, allMigrations.map(_.value.version).max)
        val solrUp = SolrUpdate(cfg, client)
        val writeVersion = SolrMigration.writeVersion(solrUp, verDoc)
        val deleteAll = SolrMigration.deleteData(0, solrUp)
        val indexAll = SolrMigration.indexAll[F](Int.MaxValue, "Index all data")

        deleteAll :: (allMigrations.filter(_.isSchemaChange) ::: List(indexAll, writeVersion))
      }

      private def allMigrations: List[SolrMigration[F]] =
        List(
          SolrMigration[F](
            1,
            "Initialize",
            setupCoreSchema
          ),
          SolrMigration[F](
            2,
            "Add folder field",
            addFolderField
          ),
          SolrMigration.indexAll(3, "Index all from database after adding folder field"),
          SolrMigration[F](
            4,
            "Add content_fr field",
            addContentField(Language.French)
          ),
          SolrMigration
            .indexAll(5, "Index all from database after adding french content field"),
          SolrMigration[F](
            6,
            "Add content_it field",
            addContentField(Language.Italian)
          ),
          SolrMigration.reIndexAll(7, "Re-Index after adding italian content field"),
          SolrMigration[F](
            8,
            "Add content_es field",
            addContentField(Language.Spanish)
          ),
          SolrMigration.reIndexAll(9, "Re-Index after adding spanish content field"),
          SolrMigration[F](
            10,
            "Add more content fields",
            addMoreContentFields
          ),
          SolrMigration.reIndexAll(11, "Re-Index after adding more content fields"),
          SolrMigration[F](
            12,
            "Add latvian content field",
            addContentField(Language.Latvian)
          ),
          SolrMigration.reIndexAll(13, "Re-Index after adding latvian content field")
        )

      def addFolderField: F[Unit] =
        addStringField(Field.folderId)

      def addMoreContentFields: F[Unit] = {
        val remain = List[Language](
          Language.Norwegian,
          Language.Romanian,
          Language.Swedish,
          Language.Finnish,
          Language.Danish,
          Language.Czech,
          Language.Dutch,
          Language.Portuguese,
          Language.Russian
        )
        remain.traverse(addContentField).map(_ => ())
      }

      def setupCoreSchema: F[Unit] = {
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

        val cntLang = List(Language.German, Language.English, Language.French).traverse {
          case l @ Language.German =>
            addTextField(l.some)(Field.content_de)
          case l @ Language.English =>
            addTextField(l.some)(Field.content_en)
          case l @ Language.French =>
            addTextField(l.some)(Field.content_fr)
          case _ =>
            ().pure[F]
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

      private def addContentField(lang: Language): F[Unit] =
        addTextField(Some(lang))(Field.contentField(lang))

      private def addTextField(lang: Option[Language])(field: Field): F[Unit] =
        lang match {
          case None =>
            run(DeleteField.command(DeleteField(field))).attempt *>
              run(AddField.command(AddField.textGeneral(field)))
          case Some(lang) =>
            run(DeleteField.command(DeleteField(field))).attempt *>
              run(AddField.command(AddField.textLang(field, lang)))
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

    def textGeneral(field: Field): AddField =
      AddField(field, "text_general", true, true, false)

    def textLang(field: Field, lang: Language): AddField =
      if (lang == Language.Czech) AddField(field, s"text_cz", true, true, false)
      else AddField(field, s"text_${lang.iso2}", true, true, false)
  }

  case class DeleteField(name: Field)
  object DeleteField {
    implicit val encoder: Encoder[DeleteField] =
      deriveEncoder[DeleteField]

    def command(body: DeleteField): Json =
      Map("delete-field" -> body.asJson).asJson
  }
}
