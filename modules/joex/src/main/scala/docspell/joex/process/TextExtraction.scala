package docspell.joex.process

import bitpeace.RangeDef
import cats.implicits._
import cats.effect.{Blocker, ContextShift, Sync}
import docspell.common.{Duration, Language, ProcessItemArgs}
import docspell.joex.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.records.{RAttachment, RAttachmentMeta}
import docspell.text.ocr.{TextExtract, Config => OcrConfig}

object TextExtraction {

  def apply[F[_]: Sync: ContextShift](
      cfg: OcrConfig,
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _     <- ctx.logger.info("Starting text extraction")
        start <- Duration.stopTime[F]
        txt   <- item.attachments.traverse(extractTextToMeta(ctx, cfg, ctx.args.meta.language))
        _     <- ctx.logger.debug("Storing extracted texts")
        _     <- txt.toList.traverse(rm => ctx.store.transact(RAttachmentMeta.upsert(rm)))
        dur   <- start
        _     <- ctx.logger.info(s"Text extraction finished in ${dur.formatExact}")
      } yield item.copy(metas = txt)
    }

  def extractTextToMeta[F[_]: Sync: ContextShift](
      ctx: Context[F, _],
      cfg: OcrConfig,
      lang: Language
  )(ra: RAttachment): F[RAttachmentMeta] =
    for {
      _    <- ctx.logger.debug(s"Extracting text for attachment ${ra.name}")
      dst  <- Duration.stopTime[F]
      txt  <- extractText(cfg, lang, ctx.store, ctx.blocker)(ra)
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
  )(ra: RAttachment): F[Option[String]] = {
    val data = store.bitpeace
      .get(ra.fileId.id)
      .unNoneTerminate
      .through(store.bitpeace.fetchData2(RangeDef.all))

    TextExtract.extract(data, blocker, lang.iso3, ocrConfig).compile.last
  }
}
