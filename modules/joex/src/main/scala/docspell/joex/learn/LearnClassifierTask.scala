package docspell.joex.learn

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.{Pipe, Stream}

import docspell.analysis.TextAnalyser
import docspell.analysis.nlp.ClassifierModel
import docspell.analysis.nlp.TextClassifier.Data
import docspell.backend.ops.OCollective
import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler._
import docspell.store.queries.QItem
import docspell.store.records.RClassifierSetting

import bitpeace.MimetypeHint

object LearnClassifierTask {
  val noClass = "__NONE__"
  val pageSep = " --n-- "

  type Args = LearnClassifierArgs

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling learn-classifier task"))

  def apply[F[_]: Sync: ContextShift](
      cfg: Config.TextAnalysis,
      blocker: Blocker,
      analyser: TextAnalyser[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      (for {
        sett <- findActiveSettings[F](ctx, cfg)
        data = selectItems(
          ctx,
          math.min(cfg.classification.itemCount, sett.itemCount).toLong,
          sett.category.getOrElse("")
        )
        _ <- OptionT.liftF(
          analyser
            .classifier(blocker)
            .trainClassifier[Unit](ctx.logger, data)(Kleisli(handleModel(ctx, blocker)))
        )
      } yield ())
        .getOrElseF(logInactiveWarning(ctx.logger))
    }

  private def handleModel[F[_]: Sync: ContextShift](
      ctx: Context[F, Args],
      blocker: Blocker
  )(trainedModel: ClassifierModel): F[Unit] =
    for {
      oldFile <- ctx.store.transact(
        RClassifierSetting.findById(ctx.args.collective).map(_.flatMap(_.fileId))
      )
      _ <- ctx.logger.info("Storing new trained model")
      fileData = fs2.io.file.readAll(trainedModel.model, blocker, 4096)
      newFile <-
        ctx.store.bitpeace.saveNew(fileData, 4096, MimetypeHint.none).compile.lastOrError
      _ <- ctx.store.transact(
        RClassifierSetting.updateFile(ctx.args.collective, Ident.unsafe(newFile.id))
      )
      _ <- ctx.logger.debug(s"New model stored at file ${newFile.id}")
      _ <- oldFile match {
        case Some(fid) =>
          ctx.logger.debug(s"Deleting old model file ${fid.id}") *>
            ctx.store.bitpeace.delete(fid.id).compile.drain
        case None => ().pure[F]
      }
    } yield ()

  private def selectItems[F[_]](
      ctx: Context[F, Args],
      max: Long,
      category: String
  ): Stream[F, Data] = {
    val connStream =
      for {
        item <- QItem.findAllNewesFirst(ctx.args.collective, 10).through(restrictTo(max))
        tt <- Stream.eval(
          QItem.resolveTextAndTag(ctx.args.collective, item, category, pageSep)
        )
      } yield Data(tt.tag.map(_.name).getOrElse(noClass), item.id, tt.text.trim)
    ctx.store.transact(connStream.filter(_.text.nonEmpty))
  }

  private def restrictTo[F[_], A](max: Long): Pipe[F, A, A] =
    if (max <= 0) identity
    else _.take(max)

  private def findActiveSettings[F[_]: Sync](
      ctx: Context[F, Args],
      cfg: Config.TextAnalysis
  ): OptionT[F, OCollective.Classifier] =
    if (cfg.classification.enabled)
      OptionT(ctx.store.transact(RClassifierSetting.findById(ctx.args.collective)))
        .filter(_.enabled)
        .filter(_.category.nonEmpty)
        .map(OCollective.Classifier.fromRecord)
    else
      OptionT.none

  private def logInactiveWarning[F[_]: Sync](logger: Logger[F]): F[Unit] =
    logger.warn(
      "Classification is disabled. Check joex config and the collective settings."
    )
}
