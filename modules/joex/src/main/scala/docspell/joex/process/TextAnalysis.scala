package docspell.joex.process

import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.analysis.nlp.StanfordSettings
import docspell.common._
import docspell.joex.process.ItemData.AttachmentDates
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachmentMeta

object TextAnalysis {

  def apply[F[_]: Sync](
      analyser: TextAnalyser[F]
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Starting text analysis")
        s <- Duration.stopTime[F]
        t <-
          item.metas.toList
            .traverse(
              annotateAttachment[F](ctx.args, ctx.logger, analyser)
            )
        _ <- ctx.logger.debug(s"Storing tags: ${t.map(_._1.copy(content = None))}")
        _ <- t.traverse(m =>
          ctx.store.transact(RAttachmentMeta.updateLabels(m._1.id, m._1.nerlabels))
        )
        e <- s
        _ <- ctx.logger.info(s"Text-Analysis finished in ${e.formatExact}")
        v = t.toVector
      } yield item.copy(metas = v.map(_._1), dateLabels = v.map(_._2))
    }

  def annotateAttachment[F[_]: Sync](
      args: ProcessItemArgs,
      logger: Logger[F],
      analyser: TextAnalyser[F]
  )(rm: RAttachmentMeta): F[(RAttachmentMeta, AttachmentDates)] = {
    val settings = StanfordSettings(args.meta.language, false, None)
    for {
      labels <- analyser.annotate(
        logger,
        settings,
        args.meta.collective,
        rm.content.getOrElse("")
      )
    } yield (rm.copy(nerlabels = labels.all.toList), AttachmentDates(rm, labels.dates))
  }
}
