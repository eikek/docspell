package docspell.joex.process

import java.nio.file.Paths

import cats.effect._
import cats.implicits._

import docspell.analysis.TextAnalyser
import docspell.analysis.nlp.StanfordSettings
import docspell.analysis.split.TextSplitter
import docspell.common._
import docspell.joex.process.ItemData.AttachmentDates
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.queries.QCollective
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
              annotateAttachment[F](ctx, analyser)
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
      ctx: Context[F, ProcessItemArgs],
      analyser: TextAnalyser[F]
  )(rm: RAttachmentMeta): F[(RAttachmentMeta, AttachmentDates)] = {
    val settings = StanfordSettings(ctx.args.meta.language, false, None)
    for {
      names <- ctx.store.transact(QCollective.allNames(ctx.args.meta.collective))
      temp  <- File.mkTempFile(Paths.get("."), "textanalysis")
      _     <- File.writeString(temp, mkNerConfig(names))
      sett = settings.copy(regexNer = Some(temp))
      labels <- analyser.annotate(
        ctx.logger,
        sett,
        ctx.args.meta.collective,
        rm.content.getOrElse("")
      )
      _ <- File.deleteFile(temp)
    } yield (rm.copy(nerlabels = labels.all.toList), AttachmentDates(rm, labels.dates))
  }

  def mkNerConfig(names: QCollective.Names): String = {
    val orgs = names.org
      .flatMap(Pattern(3))
      .distinct
      .map(_.toRow("ORGANIZATION", "LOCATION,PERSON,MISC"))

    val pers =
      names.pers
        .flatMap(Pattern(2))
        .distinct
        .map(_.toRow("PERSON", "LOCATION,MISC"))

    val equips =
      names.equip
        .flatMap(Pattern(1))
        .distinct
        .map(_.toRow("MISC", "LOCATION"))

    (orgs ++ pers ++ equips).mkString("\n")
  }

  case class Pattern(value: String, weight: Int) {
    def toRow(tag: String, overrideTags: String): String =
      s"$value\t$tag\t$overrideTags\t$weight"
  }

  object Pattern {
    def apply(weight: Int)(str: String): Vector[Pattern] = {
      val delims = " \t\n\r".toSet
      val words =
        TextSplitter.split(str, delims).toVector.map(w => s"(?i)${w.toLower.value}")
      val tokens =
        TextSplitter
          .splitToken(str, delims)
          .toVector
          .take(3)
          .map(w => s"(?i)${w.toLower.value}")

      tokens.map(t => Pattern(t, weight)).prepended(Pattern(words.mkString(" "), weight))
    }
  }
}
