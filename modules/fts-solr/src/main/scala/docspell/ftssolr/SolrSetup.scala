/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

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
import org.log4s.getLogger

trait SolrSetup[F[_]] {

  def setupSchema: List[SolrMigration[F]]

  def remainingSetup: F[List[SolrMigration[F]]]

}

object SolrSetup {
  private val versionDocId = "6d8f09f4-8d7e-4bc9-98b8-7c89223b36dd"
  private[this] val logger = getLogger

  def apply[F[_]: Async](cfg: SolrConfig, client: Client[F]): SolrSetup[F] = {
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

        deleteAll :: (allMigrations
          .filter(_.isSchemaChange) ::: List(indexAll, writeVersion))
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
          SolrMigration.reIndexAll(13, "Re-Index after adding latvian content field"),
          SolrMigration[F](
            14,
            "Add japanese content field",
            addContentField(Language.Japanese)
          ),
          SolrMigration.reIndexAll(15, "Re-Index after adding japanese content field"),
          SolrMigration[F](
            16,
            "Add new field type for hebrew content",
            addFieldType(AddFieldType.textHe)
          ),
          SolrMigration[F](
            17,
            "Add hebrew content field",
            addContentField(Language.Hebrew)
          ),
          SolrMigration.reIndexAll(18, "Re-Index after adding hebrew content field"),
          SolrMigration[F](
            19,
            "Add hungarian",
            addContentField(Language.Hungarian)
          ),
          SolrMigration.reIndexAll(20, "Re-Index after adding hungarian content field"),
          SolrMigration[F](
            21,
            "Add new field type for lithuanian content",
            addFieldType(AddFieldType.textLit)
          ),
          SolrMigration[F](
            22,
            "Add lithuanian",
            addContentField(Language.Lithuanian)
          ),
          SolrMigration.reIndexAll(23, "Re-Index after adding lithuanian content field"),
          SolrMigration[F](
            24,
            "Add new field type for polish content",
            addFieldType(AddFieldType.textPol)
          ),
          SolrMigration[F](
            25,
            "Add polish",
            addContentField(Language.Polish)
          ),
          SolrMigration.reIndexAll(26, "Re-Index after adding polish content field"),
          SolrMigration.reIndexAll(27, "Re-Index after collective-id change"),
          SolrMigration[F](
            28,
            "Add Estonian",
            addContentField(Language.Estonian)
          ),
          SolrMigration[F](
            29,
            "Add new field type for ukrainian content",
            addFieldType(AddFieldType.textUkr)
          ),
          SolrMigration[F](
            30,
            "Add Ukrainian",
            addContentField(Language.Ukrainian)
          ),
          SolrMigration.reIndexAll(31, "Re-Index after adding Estonian and Ukrainian"),
          SolrMigration[F](
            32,
            "Add new field type for khmer content",
            addFieldType(AddFieldType.textKhm)
          ),
          SolrMigration[F](
            33,
            "Add Khmer",
            addContentField(Language.Khmer)
          ),
          SolrMigration.reIndexAll(34, "Re-Index after adding Khmer"),
          SolrMigration[F](
            35,
            "Add new field type for slovak content",
            addFieldType(AddFieldType.textSvk)
          ),
          SolrMigration[F](
            36,
            "Add Slovak",
            addContentField(Language.Slovak)
          ),
          SolrMigration.reIndexAll(37, "Re-Index after adding Slovak")
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

      private def addFieldType(ft: AddFieldType): F[Unit] =
        run(AddFieldType.command(ft)).attempt.flatMap {
          case Right(_) => ().pure[F]
          case Left(ex) =>
            Async[F].delay(
              logger.warn(s"Adding new field type '$ft' failed: ${ex.getMessage()}")
            )
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
      AddField(field, "string", stored = true, indexed = true, multiValued = false)

    def textGeneral(field: Field): AddField =
      AddField(field, "text_general", stored = true, indexed = true, multiValued = false)

    def textLang(field: Field, lang: Language): AddField =
      if (lang == Language.Czech)
        AddField(field, s"text_cz", stored = true, indexed = true, multiValued = false)
      else
        AddField(
          field,
          s"text_${lang.iso2}",
          stored = true,
          indexed = true,
          multiValued = false
        )
  }

  case class DeleteField(name: Field)
  object DeleteField {
    implicit val encoder: Encoder[DeleteField] =
      deriveEncoder[DeleteField]

    def command(body: DeleteField): Json =
      Map("delete-field" -> body.asJson).asJson
  }

  final case class AddFieldType(
      name: String,
      `class`: String,
      analyzer: AddFieldType.Analyzer
  )
  object AddFieldType {

    val textHe = AddFieldType(
      "text_he",
      "solr.TextField",
      Analyzer(
        Tokenizer("solr.StandardTokenizerFactory", Map.empty),
        List(
          Filter("solr.LowerCaseFilterFactory", Map.empty)
        )
      )
    )

    val textLit = AddFieldType(
      "text_lt",
      "solr.TextField",
      Analyzer(
        Tokenizer("solr.StandardTokenizerFactory", Map.empty),
        List(
          Filter("solr.LowerCaseFilterFactory", Map.empty)
        )
      )
    )

    val textPol = AddFieldType(
      "text_pl",
      "solr.TextField",
      Analyzer(
        Tokenizer("solr.StandardTokenizerFactory", Map.empty),
        List(
          Filter("solr.LowerCaseFilterFactory", Map.empty)
        )
      )
    )

    val textUkr = AddFieldType(
      "text_uk",
      "solr.TextField",
      Analyzer(
        Tokenizer("solr.StandardTokenizerFactory", Map.empty),
        List(
          Filter("solr.LowerCaseFilterFactory", Map.empty)
        )
      )
    )

    val textKhm = AddFieldType(
      "text_kh",
      "solr.TextField",
      Analyzer(
        Tokenizer("solr.ICUTokenizerFactory", Map.empty),
        List(
        )
      )
    )

    val textSvk = AddFieldType(
      "text_sk",
      "solr.TextField",
      Analyzer(
        Tokenizer("solr.StandardTokenizerFactory", Map.empty),
        List(
          Filter("solr.LowerCaseFilterFactory", Map.empty)
        )
      )
    )

    final case class Filter(`class`: String, attr: Map[String, String])
    final case class Tokenizer(`class`: String, attr: Map[String, String])
    final case class Analyzer(tokenizer: Tokenizer, filter: List[Filter])

    object Filter {
      implicit val jsonEncoder: Encoder[Filter] =
        Encoder.encodeJson.contramap { filter =>
          val m = filter.attr.updated("class", filter.`class`)
          m.asJson
        }
    }
    object Tokenizer {
      implicit val jsonEncoder: Encoder[Tokenizer] =
        Encoder.encodeJson.contramap { tokenizer =>
          val m = tokenizer.attr.updated("class", tokenizer.`class`)
          m.asJson
        }
    }
    object Analyzer {
      implicit val jsonEncoder: Encoder[Analyzer] =
        deriveEncoder[Analyzer]
    }

    def command(body: AddFieldType): Json =
      Map("add-field-type" -> body.asJson).asJson

    implicit val jsonEncoder: Encoder[AddFieldType] =
      deriveEncoder[AddFieldType]
  }
}
