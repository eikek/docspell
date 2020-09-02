package docspell.analysis

import cats.effect._
import cats.implicits._

import docspell.analysis.contact.Contact
import docspell.analysis.date.DateFind
import docspell.analysis.nlp.PipelineCache
import docspell.analysis.nlp.StanfordNerClassifier
import docspell.analysis.nlp.StanfordNerSettings
import docspell.analysis.nlp.StanfordTextClassifier
import docspell.analysis.nlp.TextClassifier
import docspell.common._

trait TextAnalyser[F[_]] {

  def annotate(
      logger: Logger[F],
      settings: StanfordNerSettings,
      cacheKey: Ident,
      text: String
  ): F[TextAnalyser.Result]

  def classifier(blocker: Blocker)(implicit CS: ContextShift[F]): TextClassifier[F]
}
object TextAnalyser {

  case class Result(labels: Vector[NerLabel], dates: Vector[NerDateLabel]) {

    def all: Vector[NerLabel] =
      labels ++ dates.map(dl => dl.label.copy(label = dl.date.toString))
  }

  def create[F[_]: Sync](cfg: TextAnalysisConfig): Resource[F, TextAnalyser[F]] =
    Resource
      .liftF(PipelineCache[F]())
      .map(cache =>
        new TextAnalyser[F] {
          def annotate(
              logger: Logger[F],
              settings: StanfordNerSettings,
              cacheKey: Ident,
              text: String
          ): F[TextAnalyser.Result] =
            for {
              input <- textLimit(logger, text)
              tags0 <- stanfordNer(cacheKey, settings, input)
              tags1 <- contactNer(input)
              dates <- dateNer(settings.lang, input)
              list  = tags0 ++ tags1
              spans = NerLabelSpan.build(list)
            } yield Result(spans ++ list, dates)

          def classifier(blocker: Blocker)(implicit
              CS: ContextShift[F]
          ): TextClassifier[F] =
            new StanfordTextClassifier[F](cfg.classifier, blocker)

          private def textLimit(logger: Logger[F], text: String): F[String] =
            if (text.length <= cfg.maxLength) text.pure[F]
            else
              logger.info(
                s"The text to analyse is larger than limit (${text.length} > ${cfg.maxLength})." +
                  s" Analysing only first ${cfg.maxLength} characters."
              ) *> text.take(cfg.maxLength).pure[F]

          private def stanfordNer(key: Ident, settings: StanfordNerSettings, text: String)
              : F[Vector[NerLabel]] =
            StanfordNerClassifier.nerAnnotate[F](key.id, cache)(settings, text)

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

}
