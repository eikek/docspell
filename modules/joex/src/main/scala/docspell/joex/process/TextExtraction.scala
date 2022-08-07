/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.extract.{ExtractConfig, ExtractResult, Extraction}
import docspell.ftsclient.{FtsClient, TextData}
import docspell.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.records.{RAttachment, RAttachmentMeta, RFileMeta}

object TextExtraction {

  def apply[F[_]: Async](cfg: ExtractConfig, fts: FtsClient[F], store: Store[F])(
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
            store,
            cfg,
            ctx.args.meta.language,
            ctx.args.meta.collective,
            item
          )
        )
        _ <- ctx.logger.debug("Storing extracted texts …")
        _ <-
          txt.toList.traverse(res => store.transact(RAttachmentMeta.upsert(res.am)))
        _ <- ctx.logger.debug(s"Extracted text stored.")
        idxItem = TextData.item(
          item.item.id,
          ctx.args.meta.collective,
          ctx.args.meta.folderId,
          item.item.name.some,
          None,
          ctx.args.meta.language
        )
        _ <- fts.indexData(ctx.logger, idxItem +: txt.map(_.td): _*)
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

  def extractTextIfEmpty[F[_]: Async](
      ctx: Context[F, ProcessItemArgs],
      store: Store[F],
      cfg: ExtractConfig,
      lang: Language,
      collective: CollectiveId,
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
      case Some(_) if ctx.args.isNormalProcessing =>
        ctx.logger.info("TextExtraction skipped, since text is already available.") *>
          makeTextData((rm, Nil)).pure[F]
      case _ =>
        extractTextToMeta[F](ctx, store, cfg, lang, item)(ra)
          .map(makeTextData)
    }
  }

  def extractTextToMeta[F[_]: Async](
      ctx: Context[F, _],
      store: Store[F],
      cfg: ExtractConfig,
      lang: Language,
      item: ItemData
  )(ra: RAttachment): F[(RAttachmentMeta, List[String])] =
    for {
      _ <- ctx.logger.debug(s"Extracting text for attachment ${stripAttachmentName(ra)}")
      dst <- Duration.stopTime[F]
      fids <- filesToExtract(store)(item, ra)
      res <- extractTextFallback(ctx, store, cfg, ra, lang)(fids)
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

  def extractText[F[_]: Sync](
      store: Store[F],
      extr: Extraction[F],
      lang: Language
  )(fileId: FileKey): F[ExtractResult] = {
    val data = store.fileRepo.getBytes(fileId)

    def findMime: F[MimeType] =
      OptionT(store.fileRepo.findMeta(fileId))
        .map(_.mimetype)
        .getOrElse(MimeType.octetStream)

    findMime
      .flatMap(mt => extr.extractText(data, DataType(mt), lang))
  }

  private def extractTextFallback[F[_]: Async](
      ctx: Context[F, _],
      store: Store[F],
      cfg: ExtractConfig,
      ra: RAttachment,
      lang: Language
  )(fileIds: List[FileKey]): F[Option[ExtractResult.Success]] =
    fileIds match {
      case Nil =>
        ctx.logger.error(s"Cannot extract text").map(_ => None)

      case id :: rest =>
        val extr = Extraction.create[F](ctx.logger, cfg)

        extractText[F](store, extr, lang)(id)
          .flatMap {
            case res @ ExtractResult.Success(_, _) =>
              res.some.pure[F]

            case ExtractResult.UnsupportedFormat(mt) =>
              ctx.logger
                .warn(
                  s"Cannot extract text from file ${stripAttachmentName(ra)}: unsupported format ${mt.asString}. Try with converted file."
                )
                .flatMap(_ => extractTextFallback[F](ctx, store, cfg, ra, lang)(rest))

            case ExtractResult.Failure(ex) =>
              ctx.logger
                .warn(s"Cannot extract text: ${ex.getMessage}. Try with converted file")
                .flatMap(_ => extractTextFallback[F](ctx, store, cfg, ra, lang)(rest))
          }
    }

  /** Returns the fileIds to extract text from. First, the source file is tried. If that
    * fails, the converted file is tried.
    *
    * If the source file is a PDF, then use the converted file. This may then already
    * contain the text if ocrmypdf is enabled. If it is disabled, both files are the same.
    */
  private def filesToExtract[F[_]: Sync](store: Store[F])(
      item: ItemData,
      ra: RAttachment
  ): F[List[FileKey]] =
    item.originFile.get(ra.id) match {
      case Some(sid) =>
        store.transact(RFileMeta.findMime(sid)).map {
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
