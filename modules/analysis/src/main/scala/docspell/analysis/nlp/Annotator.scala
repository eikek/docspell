/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis.nlp

import cats.effect.Sync
import cats.implicits._
import cats.{Applicative, FlatMap}

import docspell.analysis.NlpSettings
import docspell.common._

import edu.stanford.nlp.pipeline.StanfordCoreNLP

/** Analyses a text to mark certain parts with a `NerLabel`. */
trait Annotator[F[_]] { self =>
  def nerAnnotate(logger: Logger[F])(text: String): F[Vector[NerLabel]]

  def ++(next: Annotator[F])(implicit F: FlatMap[F]): Annotator[F] =
    new Annotator[F] {
      def nerAnnotate(logger: Logger[F])(text: String): F[Vector[NerLabel]] =
        for {
          n0 <- self.nerAnnotate(logger)(text)
          n1 <- next.nerAnnotate(logger)(text)
        } yield (n0 ++ n1).distinct
    }
}

object Annotator {

  /** Creates an annotator according to the given `mode` and `settings`.
    *
    * There are the following ways:
    *
    *   - disabled: it returns a no-op annotator that always gives an empty list
    *   - full: the complete stanford pipeline is used
    *   - basic: only the ner classifier is used
    *
    * Additionally, if there is a regexNer-file specified, the regexner annotator is also
    * run. In case the full pipeline is used, this is already included.
    */
  def apply[F[_]: Sync](mode: NlpMode)(settings: NlpSettings): Annotator[F] =
    mode match {
      case NlpMode.Disabled =>
        Annotator.none[F]
      case NlpMode.Full =>
        StanfordNerSettings.fromNlpSettings(settings) match {
          case Some(ss) =>
            Annotator.pipeline(StanfordNerAnnotator.makePipeline(ss))
          case None =>
            Annotator.none[F]
        }
      case NlpMode.Basic =>
        StanfordNerSettings.fromNlpSettings(settings) match {
          case Some(StanfordNerSettings.Full(lang, _, Some(file))) =>
            Annotator.basic(BasicCRFAnnotator.Cache.getAnnotator(lang)) ++
              Annotator.pipeline(StanfordNerAnnotator.regexNerPipeline(file))
          case Some(StanfordNerSettings.Full(lang, _, None)) =>
            Annotator.basic(BasicCRFAnnotator.Cache.getAnnotator(lang))
          case Some(StanfordNerSettings.RegexOnly(file)) =>
            Annotator.pipeline(StanfordNerAnnotator.regexNerPipeline(file))
          case None =>
            Annotator.none[F]
        }
      case NlpMode.RegexOnly =>
        settings.regexNer match {
          case Some(file) =>
            Annotator.pipeline(StanfordNerAnnotator.regexNerPipeline(file))
          case None =>
            Annotator.none[F]
        }
    }

  def none[F[_]: Applicative]: Annotator[F] =
    new Annotator[F] {
      def nerAnnotate(logger: Logger[F])(text: String): F[Vector[NerLabel]] =
        logger.debug("Running empty annotator. NLP not supported.") *>
          Vector.empty[NerLabel].pure[F]
    }

  def basic[F[_]: Sync](ann: BasicCRFAnnotator.Annotator): Annotator[F] =
    new Annotator[F] {
      def nerAnnotate(logger: Logger[F])(text: String): F[Vector[NerLabel]] =
        Sync[F].delay(
          BasicCRFAnnotator.nerAnnotate(ann)(text)
        )
    }

  def pipeline[F[_]: Sync](cp: StanfordCoreNLP): Annotator[F] =
    new Annotator[F] {
      def nerAnnotate(logger: Logger[F])(text: String): F[Vector[NerLabel]] =
        Sync[F].delay(StanfordNerAnnotator.nerAnnotate(cp, text))

    }

  def clearCaches[F[_]: Sync]: F[Unit] =
    Sync[F].delay {
      StanfordCoreNLP.clearAnnotatorPool()
      BasicCRFAnnotator.Cache.clearCache()
    }
}
