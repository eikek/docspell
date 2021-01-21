package docspell.joex.process

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.extract.{ExtractConfig, ExtractResult, Extraction}
import docspell.ftsclient.{FtsClient, TextData}
import docspell.joex.scheduler.{Context, Task}
import docspell.store.records.{RAttachment, RAttachmentMeta, RFileMeta}
import docspell.store.syntax.MimeTypes._

import bitpeace.{Mimetype, RangeDef}

object TextExtraction {

  def apply[F[_]: ConcurrentEffect: ContextShift](cfg: ExtractConfig, fts: FtsClient[F])(
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(
          s"Starting text extraction for ${item.attachments.size} files"
        )
        start <- Duration.stopTime[F]
        txt <- item.attachments.traverse(
          extractTextIfEmpty(
            ctx,
            cfg,
            ctx.args.meta.language,
            ctx.args.meta.collective,
            item
          )
        )
        _ <- ctx.logger.debug("Storing extracted texts …")
        _ <-
          txt.toList.traverse(res => ctx.store.transact(RAttachmentMeta.upsert(res.am)))
        _ <- ctx.logger.debug(s"Extracted text stored.")
        idxItem = TextData.item(
          item.item.id,
          ctx.args.meta.collective,
          ctx.args.meta.folderId,
          item.item.name.some,
          None
        )
        _   <- fts.indexData(ctx.logger, (idxItem +: txt.map(_.td)).toSeq: _*)
        dur <- start
        extractedTags = txt.flatMap(_.tags).distinct.toList
        _ <- ctx.logger.info(s"Text extraction finished in ${dur.formatExact}.")
        _ <-
          if (extractedTags.isEmpty) ().pure[F]
          else ctx.logger.debug(s"Found tags in file: $extractedTags")
      } yield item
        .copy(metas = txt.map(_.am))
        .appendTags(extractedTags)
    }

  // --  helpers

  case class Result(am: RAttachmentMeta, td: TextData, tags: List[String] = Nil)

  def extractTextIfEmpty[F[_]: Sync: ContextShift](
      ctx: Context[F, ProcessItemArgs],
      cfg: ExtractConfig,
      lang: Language,
      collective: Ident,
      item: ItemData
  )(ra: RAttachment): F[Result] = {
    def makeTextData(pair: (RAttachmentMeta, List[String])): Result =
      Result(
        pair._1,
        TextData.attachment(
          item.item.id,
          ra.id,
          collective,
          ctx.args.meta.folderId,
          lang,
          ra.name,
          pair._1.content
        ),
        pair._2
      )

    val rm = item.findOrCreate(ra.id, lang)
    rm.content match {
      case Some(_) =>
        ctx.logger.info("TextExtraction skipped, since text is already available.") *>
          makeTextData((rm, Nil)).pure[F]
      case None =>
        extractTextToMeta[F](ctx, cfg, lang, item)(ra)
          .map(makeTextData)
    }
  }

  def extractTextToMeta[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      cfg: ExtractConfig,
      lang: Language,
      item: ItemData
  )(ra: RAttachment): F[(RAttachmentMeta, List[String])] =
    for {
      _    <- ctx.logger.debug(s"Extracting text for attachment ${stripAttachmentName(ra)}")
      dst  <- Duration.stopTime[F]
      fids <- filesToExtract(ctx)(item, ra)
      res  <- extractTextFallback(ctx, cfg, ra, lang)(fids)
      meta = item.changeMeta(
        ra.id,
        lang,
        rm =>
          rm.setContentIfEmpty(
            res.map(_.appendPdfMetaToText.text.trim).filter(_.nonEmpty)
          )
      )
      tags = res.flatMap(_.pdfMeta).map(_.keywordList).getOrElse(Nil)
      est <- dst
      _ <- ctx.logger.info(
        s"Extracting text for attachment ${stripAttachmentName(ra)} finished in ${est.formatExact}"
      )
    } yield (meta, tags)

  def extractText[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      extr: Extraction[F],
      lang: Language
  )(fileId: Ident): F[ExtractResult] = {
    val data = ctx.store.bitpeace
      .get(fileId.id)
      .unNoneTerminate
      .through(ctx.store.bitpeace.fetchData2(RangeDef.all))

    def findMime: F[Mimetype] =
      OptionT(ctx.store.transact(RFileMeta.findById(fileId)))
        .map(_.mimetype)
        .getOrElse(Mimetype.`application/octet-stream`)

    findMime
      .flatMap(mt => extr.extractText(data, DataType(mt.toLocal), lang))
  }

  private def extractTextFallback[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      cfg: ExtractConfig,
      ra: RAttachment,
      lang: Language
  )(fileIds: List[Ident]): F[Option[ExtractResult.Success]] =
    fileIds match {
      case Nil =>
        ctx.logger.error(s"Cannot extract text").map(_ => None)

      case id :: rest =>
        val extr = Extraction.create[F](ctx.blocker, ctx.logger, cfg)

        extractText[F](ctx, extr, lang)(id)
          .flatMap({
            case res @ ExtractResult.Success(_, _) =>
              res.some.pure[F]

            case ExtractResult.UnsupportedFormat(mt) =>
              ctx.logger
                .warn(
                  s"Cannot extract text from file ${stripAttachmentName(ra)}: unsupported format ${mt.asString}. Try with converted file."
                )
                .flatMap(_ => extractTextFallback[F](ctx, cfg, ra, lang)(rest))

            case ExtractResult.Failure(ex) =>
              ctx.logger
                .warn(s"Cannot extract text: ${ex.getMessage}. Try with converted file")
                .flatMap(_ => extractTextFallback[F](ctx, cfg, ra, lang)(rest))
          })
    }

  /** Returns the fileIds to extract text from. First, the source file
    * is tried. If that fails, the converted file is tried.
    *
    * If the source file is a PDF, then use the converted file. This
    * may then already contain the text if ocrmypdf is enabled. If it
    * is disabled, both files are the same.
    */
  private def filesToExtract[F[_]: Sync](ctx: Context[F, _])(
      item: ItemData,
      ra: RAttachment
  ): F[List[Ident]] =
    item.originFile.get(ra.id) match {
      case Some(sid) =>
        ctx.store.transact(RFileMeta.findMime(sid)).map {
          case Some(MimeType.PdfMatch(_)) =>
            List(ra.fileId)
          case _ =>
            List(sid, ra.fileId).distinct
        }
      case None => List(ra.fileId).pure[F]
    }

  private def stripAttachmentName(ra: RAttachment): String =
    ra.name
      .map(s => if (s.endsWith(".pdf") && s.count(_ == '.') > 1) s.dropRight(4) else s)
      .getOrElse("<no-name>")
}
