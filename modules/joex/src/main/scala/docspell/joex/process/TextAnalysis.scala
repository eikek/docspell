/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.Traverse
import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.analysis.classifier.TextClassifier
import docspell.analysis.{NlpSettings, TextAnalyser}
import docspell.common.MetaProposal.Candidate
import docspell.common._
import docspell.joex.Config
import docspell.joex.analysis.RegexNerFile
import docspell.joex.learn.{ClassifierName, Classify, LearnClassifierTask}
import docspell.joex.process.ItemData.AttachmentDates
import docspell.scheduler.Context
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.records.{RAttachmentMeta, RClassifierSetting}

object TextAnalysis {
  type Args = ProcessItemArgs

  def apply[F[_]: Async: Files](
      cfg: Config.TextAnalysis,
      analyser: TextAnalyser[F],
      nerFile: RegexNerFile[F],
      store: Store[F]
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
          store.transact(RAttachmentMeta.updateLabels(m._1.id, m._1.nerlabels))
        )

        v = t.toVector
        autoTagEnabled <- getActiveAutoTag(ctx, store, cfg)
        tag <-
          if (autoTagEnabled)
            predictTags(ctx, store, cfg, item.metas, analyser.classifier)
          else List.empty[String].pure[F]

        classProposals <-
          if (cfg.classification.enabled)
            predictItemEntities(ctx, store, cfg, item.metas, analyser.classifier)
          else MetaProposalList.empty.pure[F]

        e <- s
        _ <- ctx.logger.info(s"Text-Analysis finished in ${e.formatExact}")
      } yield item
        .copy(
          metas = v.map(_._1),
          dateLabels = v.map(_._2),
          classifyProposals = classProposals,
          classifyTags = tag
        )
    }

  def annotateAttachment[F[_]: Sync](
      ctx: Context[F, Args],
      analyser: TextAnalyser[F],
      nerFile: RegexNerFile[F]
  )(rm: RAttachmentMeta): F[(RAttachmentMeta, AttachmentDates)] = {
    val settings = NlpSettings(ctx.args.meta.language, highRecall = false, None)
    for {
      customNer <- nerFile.makeFile(ctx.args.meta.collective)
      sett = settings.copy(regexNer = customNer)
      labels <- analyser.annotate(
        ctx.logger,
        sett,
        ctx.args.meta.collective.valueAsIdent,
        rm.content.getOrElse("")
      )
    } yield (rm.copy(nerlabels = labels.all.toList), AttachmentDates(rm, labels.dates))
  }

  def predictTags[F[_]: Async: Files](
      ctx: Context[F, Args],
      store: Store[F],
      cfg: Config.TextAnalysis,
      metas: Vector[RAttachmentMeta],
      classifier: TextClassifier[F]
  ): F[List[String]] = {
    val text = metas.flatMap(_.content).mkString(LearnClassifierTask.pageSep)
    val classifyWith: ClassifierName => F[Option[String]] =
      makeClassify(ctx, store, cfg, classifier)(text)

    for {
      names <- store.transact(
        ClassifierName.findTagClassifiers(ctx.args.meta.collective)
      )
      _ <- ctx.logger.debug(s"Guessing tags for ${names.size} categories")
      tags <- names.traverse(classifyWith)
    } yield tags.flatten
  }

  def predictItemEntities[F[_]: Async: Files](
      ctx: Context[F, Args],
      store: Store[F],
      cfg: Config.TextAnalysis,
      metas: Vector[RAttachmentMeta],
      classifier: TextClassifier[F]
  ): F[MetaProposalList] = {
    val text = metas.flatMap(_.content).mkString(LearnClassifierTask.pageSep)

    def classifyWith(
        cname: ClassifierName,
        mtype: MetaProposalType
    ): F[Option[MetaProposal]] =
      for {
        label <- makeClassify(ctx, store, cfg, classifier)(text).apply(cname)
      } yield label.map(str =>
        MetaProposal(mtype, Candidate(IdRef(Ident.unsafe(""), str), Set.empty))
      )

    Traverse[List]
      .sequence(
        List(
          classifyWith(ClassifierName.correspondentOrg, MetaProposalType.CorrOrg),
          classifyWith(ClassifierName.correspondentPerson, MetaProposalType.CorrPerson),
          classifyWith(ClassifierName.concernedPerson, MetaProposalType.ConcPerson),
          classifyWith(ClassifierName.concernedEquip, MetaProposalType.ConcEquip)
        )
      )
      .map(_.flatten)
      .map(MetaProposalList.apply)
  }

  private def makeClassify[F[_]: Async: Files](
      ctx: Context[F, Args],
      store: Store[F],
      cfg: Config.TextAnalysis,
      classifier: TextClassifier[F]
  )(text: String): ClassifierName => F[Option[String]] =
    Classify[F](
      ctx.logger,
      cfg.workingDir,
      store,
      classifier,
      ctx.args.meta.collective,
      text
    )

  private def getActiveAutoTag[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      cfg: Config.TextAnalysis
  ): F[Boolean] =
    if (cfg.classification.enabled)
      store
        .transact(RClassifierSetting.findById(ctx.args.meta.collective))
        .map(_.exists(_.autoTagEnabled))
        .flatTap(enabled =>
          if (enabled) ().pure[F]
          else ctx.logger.info("Classification is disabled. Check config or settings.")
        )
    else
      ctx.logger.info("Classification is disabled.") *> false.pure[F]

}
