package docspell.joex.process

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.analysis.nlp.ClassifierModel
import docspell.analysis.nlp.StanfordNerSettings
import docspell.analysis.nlp.TextClassifier
import docspell.common._
import docspell.joex.Config
import docspell.joex.analysis.RegexNerFile
import docspell.joex.learn.LearnClassifierTask
import docspell.joex.process.ItemData.AttachmentDates
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachmentMeta
import docspell.store.records.RClassifierSetting

import bitpeace.RangeDef

object TextAnalysis {
  type Args = ProcessItemArgs

  def apply[F[_]: Sync: ContextShift](
      cfg: Config.TextAnalysis,
      analyser: TextAnalyser[F],
      nerFile: RegexNerFile[F]
  )(item: ItemData): Task[F, Args, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Starting text analysis")
        s <- Duration.stopTime[F]
        t <-
          item.metas.toList
            .traverse(
              annotateAttachment[F](ctx, analyser, nerFile)
            )
        _ <- ctx.logger.debug(s"Storing tags: ${t.map(_._1.copy(content = None))}")
        _ <- t.traverse(m =>
          ctx.store.transact(RAttachmentMeta.updateLabels(m._1.id, m._1.nerlabels))
        )
        e <- s
        _ <- ctx.logger.info(s"Text-Analysis finished in ${e.formatExact}")
        v = t.toVector
        tag <- predictTag(ctx, cfg, item.metas, analyser.classifier(ctx.blocker)).value
      } yield item
        .copy(metas = v.map(_._1), dateLabels = v.map(_._2))
        .appendTags(tag.toSeq)
    }

  def annotateAttachment[F[_]: Sync](
      ctx: Context[F, Args],
      analyser: TextAnalyser[F],
      nerFile: RegexNerFile[F]
  )(rm: RAttachmentMeta): F[(RAttachmentMeta, AttachmentDates)] = {
    val settings = StanfordNerSettings(ctx.args.meta.language, false, None)
    for {
      customNer <- nerFile.makeFile(ctx.args.meta.collective)
      sett = settings.copy(regexNer = customNer)
      labels <- analyser.annotate(
        ctx.logger,
        sett,
        ctx.args.meta.collective,
        rm.content.getOrElse("")
      )
    } yield (rm.copy(nerlabels = labels.all.toList), AttachmentDates(rm, labels.dates))
  }

  def predictTag[F[_]: Sync: ContextShift](
      ctx: Context[F, Args],
      cfg: Config.TextAnalysis,
      metas: Vector[RAttachmentMeta],
      classifier: TextClassifier[F]
  ): OptionT[F, String] =
    for {
      model <- findActiveModel(ctx, cfg)
      _     <- OptionT.liftF(ctx.logger.info(s"Guessing tag …"))
      text = metas.flatMap(_.content).mkString(LearnClassifierTask.pageSep)
      modelData =
        ctx.store.bitpeace
          .get(model.id)
          .unNoneTerminate
          .through(ctx.store.bitpeace.fetchData2(RangeDef.all))
      cls <- OptionT(File.withTempDir(cfg.workingDir, "classify").use { dir =>
        val modelFile = dir.resolve("model.ser.gz")
        modelData
          .through(fs2.io.file.writeAll(modelFile, ctx.blocker))
          .compile
          .drain
          .flatMap(_ => classifier.classify(ctx.logger, ClassifierModel(modelFile), text))
      }).filter(_ != LearnClassifierTask.noClass)
      _ <- OptionT.liftF(ctx.logger.debug(s"Guessed tag: ${cls}"))
    } yield cls

  private def findActiveModel[F[_]: Sync](
      ctx: Context[F, Args],
      cfg: Config.TextAnalysis
  ): OptionT[F, Ident] =
    if (cfg.classification.enabled)
      OptionT(ctx.store.transact(RClassifierSetting.findById(ctx.args.meta.collective)))
        .filter(_.enabled)
        .mapFilter(_.fileId)
    else
      OptionT.none

}
