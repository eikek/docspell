package docspell.joex.process

import fs2.Stream
import bitpeace.{Mimetype, RangeDef}
import cats.data.OptionT
import cats.implicits._
import cats.effect._
import docspell.common._
import docspell.extract.{ExtractConfig, ExtractResult, Extraction}
import docspell.joex.scheduler.{Context, Task}
import docspell.store.records.{RAttachment, RAttachmentMeta, RFileMeta}
import docspell.store.syntax.MimeTypes._
import docspell.ftsclient.{FtsClient, TextData}

object TextExtraction {

  def apply[F[_]: ConcurrentEffect: ContextShift](cfg: ExtractConfig, fts: FtsClient[F])(
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _     <- ctx.logger.info("Starting text extraction")
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
        _   <- ctx.logger.debug("Storing extracted texts")
        _   <- txt.toList.traverse(rm => ctx.store.transact(RAttachmentMeta.upsert(rm._1)))
        _   <- fts.indexData(Stream.emits(txt.map(_._2)))
        dur <- start
        _   <- ctx.logger.info(s"Text extraction finished in ${dur.formatExact}")
      } yield item.copy(metas = txt.map(_._1))
    }

  def extractTextIfEmpty[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      cfg: ExtractConfig,
      lang: Language,
      collective: Ident,
      item: ItemData
  )(ra: RAttachment): F[(RAttachmentMeta, TextData)] = {
    def makeTextData(rm: RAttachmentMeta): (RAttachmentMeta, TextData) =
      (
        rm,
        TextData.attachment(
          item.item.id,
          ra.id,
          collective,
          ra.name,
          rm.content
        )
      )

    val rm = item.findOrCreate(ra.id)
    rm.content match {
      case Some(_) =>
        ctx.logger.info("TextExtraction skipped, since text is already available.") *>
          makeTextData(rm).pure[F]
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
  )(ra: RAttachment): F[RAttachmentMeta] =
    for {
      _   <- ctx.logger.debug(s"Extracting text for attachment ${stripAttachmentName(ra)}")
      dst <- Duration.stopTime[F]
      txt <- extractTextFallback(ctx, cfg, ra, lang)(filesToExtract(item, ra))
      meta = item.changeMeta(
        ra.id,
        rm => rm.setContentIfEmpty(txt.map(_.trim).filter(_.nonEmpty))
      )
      est <- dst
      _ <- ctx.logger.info(
        s"Extracting text for attachment ${stripAttachmentName(ra)} finished in ${est.formatExact}"
      )
    } yield meta

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
  )(fileIds: List[Ident]): F[Option[String]] =
    fileIds match {
      case Nil =>
        ctx.logger.error(s"Cannot extract text").map(_ => None)

      case id :: rest =>
        val extr = Extraction.create[F](ctx.blocker, ctx.logger, cfg)

        extractText[F](ctx, extr, lang)(id)
          .flatMap({
            case ExtractResult.Success(txt) =>
              txt.some.pure[F]

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
    */
  private def filesToExtract(item: ItemData, ra: RAttachment): List[Ident] =
    item.originFile.get(ra.id) match {
      case Some(sid) => List(sid, ra.fileId).distinct
      case None      => List(ra.fileId)
    }

  private def stripAttachmentName(ra: RAttachment): String =
    ra.name
      .map(s => if (s.endsWith(".pdf") && s.count(_ == '.') > 1) s.dropRight(4) else s)
      .getOrElse("<no-name>")
}
