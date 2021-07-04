/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis

import cats.Applicative
import cats.effect._
import cats.implicits._

import docspell.analysis.classifier.{StanfordTextClassifier, TextClassifier}
import docspell.analysis.contact.Contact
import docspell.analysis.date.DateFind
import docspell.analysis.nlp._
import docspell.common._

import org.log4s.getLogger

trait TextAnalyser[F[_]] {

  def annotate(
      logger: Logger[F],
      settings: NlpSettings,
      cacheKey: Ident,
      text: String
  ): F[TextAnalyser.Result]

  def classifier: TextClassifier[F]
}
object TextAnalyser {
  private[this] val logger = getLogger

  case class Result(labels: Vector[NerLabel], dates: Vector[NerDateLabel]) {

    def all: Vector[NerLabel] =
      labels ++ dates.map(dl => dl.label.copy(label = dl.date.toString))
  }

  def create[F[_]: Async](cfg: TextAnalysisConfig): Resource[F, TextAnalyser[F]] =
    Resource
      .eval(Nlp(cfg.nlpConfig))
      .map(stanfordNer =>
        new TextAnalyser[F] {
          def annotate(
              logger: Logger[F],
              settings: NlpSettings,
              cacheKey: Ident,
              text: String
          ): F[TextAnalyser.Result] =
            for {
              input <- textLimit(logger, text)
              tags0 <- stanfordNer(Nlp.Input(cacheKey, settings, logger, input))
              tags1 <- contactNer(input)
              dates <- dateNer(settings.lang, input)
              list  = tags0 ++ tags1
              spans = NerLabelSpan.build(list)
            } yield Result(spans ++ list, dates)

          def classifier: TextClassifier[F] =
            new StanfordTextClassifier[F](cfg.classifier)

          private def textLimit(logger: Logger[F], text: String): F[String] =
            if (cfg.maxLength <= 0)
              logger.debug("Max text length limit disabled.") *> text.pure[F]
            else if (text.length <= cfg.maxLength || cfg.maxLength <= 0) text.pure[F]
            else
              logger.info(
                s"The text to analyse is larger than limit (${text.length} > ${cfg.maxLength})." +
                  s" Analysing only first ${cfg.maxLength} characters."
              ) *> text.take(cfg.maxLength).pure[F]

          private def contactNer(text: String): F[Vector[NerLabel]] =
            Sync[F].delay {
              Contact.annotate(text)
            }

          private def dateNer(lang: Language, text: String): F[Vector[NerDateLabel]] =
            Sync[F].delay {
              DateFind.findDates(text, lang).toVector
            }
        }
      )

  /** Provides the nlp pipeline based on the configuration. */
  private object Nlp {
    def apply[F[_]: Async](
        cfg: TextAnalysisConfig.NlpConfig
    ): F[Input[F] => F[Vector[NerLabel]]] =
      cfg.mode match {
        case NlpMode.Disabled =>
          Logger.log4s(logger).info("NLP is disabled as defined in config.") *>
            Applicative[F].pure(_ => Vector.empty[NerLabel].pure[F])
        case _ =>
          PipelineCache(cfg.clearInterval)(
            Annotator[F](cfg.mode),
            Annotator.clearCaches[F]
          )
            .map(annotate[F])
      }

    final case class Input[F[_]](
        key: Ident,
        settings: NlpSettings,
        logger: Logger[F],
        text: String
    )

    def annotate[F[_]: Async](
        cache: PipelineCache[F]
    )(input: Input[F]): F[Vector[NerLabel]] =
      cache
        .obtain(input.key.id, input.settings)
        .use(ann => ann.nerAnnotate(input.logger)(input.text))

  }
}
