package docspell.joex.process

import bitpeace.RangeDef
import cats.implicits._
import cats.effect.{Blocker, ContextShift, Sync}
import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.records.{RAttachment, RAttachmentMeta}
import docspell.extract.ocr.{TextExtract, Config => OcrConfig}

object TextExtraction {

  def apply[F[_]: Sync: ContextShift](
      cfg: OcrConfig,
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _     <- ctx.logger.info("Starting text extraction")
        start <- Duration.stopTime[F]
        txt   <- item.attachments.traverse(extractTextToMeta(ctx, cfg, ctx.args.meta.language, item))
        _     <- ctx.logger.debug("Storing extracted texts")
        _     <- txt.toList.traverse(rm => ctx.store.transact(RAttachmentMeta.upsert(rm)))
        dur   <- start
        _     <- ctx.logger.info(s"Text extraction finished in ${dur.formatExact}")
      } yield item.copy(metas = txt)
    }

  def extractTextToMeta[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      cfg: OcrConfig,
    lang: Language,
    item: ItemData
  )(ra: RAttachment): F[RAttachmentMeta] =
    for {
      _    <- ctx.logger.debug(s"Extracting text for attachment ${ra.name}")
      dst  <- Duration.stopTime[F]
      txt  <- extractTextFallback(ctx, cfg, lang)(filesToExtract(item, ra))
      meta = RAttachmentMeta.empty(ra.id).copy(content = txt.map(_.trim).filter(_.nonEmpty))
      est  <- dst
      _ <- ctx.logger.debug(
            s"Extracting text for attachment ${ra.name} finished in ${est.formatExact}"
          )
    } yield meta

  def extractText[F[_]: Sync: ContextShift](
      ocrConfig: OcrConfig,
      lang: Language,
      store: Store[F],
      blocker: Blocker
  )(fileId: Ident): F[Option[String]] = {
    val data = store.bitpeace
      .get(fileId.id)
      .unNoneTerminate
      .through(store.bitpeace.fetchData2(RangeDef.all))

    TextExtract.extract(data, blocker, lang.iso3, ocrConfig).compile.last
  }

  private def extractTextFallback[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      ocrConfig: OcrConfig,
      lang: Language,
  )(fileIds: List[Ident]): F[Option[String]] = {
    fileIds match {
      case Nil =>
        ctx.logger.error(s"Cannot extract text").map(_ => None)

      case id :: rest =>
        extractText[F](ocrConfig, lang, ctx.store, ctx.blocker)(id).
          recoverWith({
            case ex =>
              ctx.logger.warn(s"Cannot extract text: ${ex.getMessage}. Try with converted file").
                flatMap(_ => extractTextFallback[F](ctx, ocrConfig, lang)(rest))
          })
    }
  }

  /** Returns the fileIds to extract text from. First, the source file
    * is tried. If that fails, the converted file is tried.
    */
  private def filesToExtract(item: ItemData, ra: RAttachment): List[Ident] =
    item.originFile.get(ra.id) match {
      case Some(sid) => List(sid, ra.fileId).distinct
      case None => List(ra.fileId)
    }
}
