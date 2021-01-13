package docspell.analysis

import cats.Applicative
import cats.effect._
import cats.implicits._

import docspell.analysis.classifier.{StanfordTextClassifier, TextClassifier}
import docspell.analysis.contact.Contact
import docspell.analysis.date.DateFind
import docspell.analysis.nlp._
import docspell.common._

import edu.stanford.nlp.pipeline.StanfordCoreNLP

trait TextAnalyser[F[_]] {

  def annotate(
      logger: Logger[F],
      settings: StanfordNerSettings,
      cacheKey: Ident,
      text: String
  ): F[TextAnalyser.Result]

  def classifier: TextClassifier[F]
}
object TextAnalyser {

  case class Result(labels: Vector[NerLabel], dates: Vector[NerDateLabel]) {

    def all: Vector[NerLabel] =
      labels ++ dates.map(dl => dl.label.copy(label = dl.date.toString))
  }

  def create[F[_]: Concurrent: Timer: ContextShift](
      cfg: TextAnalysisConfig,
      blocker: Blocker
  ): Resource[F, TextAnalyser[F]] =
    Resource
      .liftF(Nlp(cfg.nlpConfig))
      .map(stanfordNer =>
        new TextAnalyser[F] {
          def annotate(
              logger: Logger[F],
              settings: StanfordNerSettings,
              cacheKey: Ident,
              text: String
          ): F[TextAnalyser.Result] =
            for {
              input <- textLimit(logger, text)
              tags0 <- stanfordNer(Nlp.Input(cacheKey, settings, input))
              tags1 <- contactNer(input)
              dates <- dateNer(settings.lang, input)
              list  = tags0 ++ tags1
              spans = NerLabelSpan.build(list)
            } yield Result(spans ++ list, dates)

          def classifier: TextClassifier[F] =
            new StanfordTextClassifier[F](cfg.classifier, blocker)

          private def textLimit(logger: Logger[F], text: String): F[String] =
            if (text.length <= cfg.maxLength) text.pure[F]
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

  private object Nlp {

    def apply[F[_]: Concurrent: Timer: BracketThrow](
        cfg: TextAnalysisConfig.NlpConfig
    ): F[Input => F[Vector[NerLabel]]] =
      cfg.mode match {
        case NlpMode.Full =>
          PipelineCache.full(cfg.clearInterval).map(cache => full(cache))
        case NlpMode.Basic =>
          PipelineCache.basic(cfg.clearInterval).map(cache => basic(cache))
        case NlpMode.Disabled =>
          Applicative[F].pure(_ => Vector.empty[NerLabel].pure[F])
      }

    final case class Input(key: Ident, settings: StanfordNerSettings, text: String)

    def full[F[_]: BracketThrow](
        cache: PipelineCache[F, StanfordCoreNLP]
    )(input: Input): F[Vector[NerLabel]] =
      StanfordNerAnnotator.nerAnnotate(input.key.id, cache)(input.settings, input.text)

    def basic[F[_]: BracketThrow](
        cache: PipelineCache[F, BasicCRFAnnotator.Annotator]
    )(input: Input): F[Vector[NerLabel]] =
      BasicCRFAnnotator.nerAnnotate(input.key.id, cache)(input.settings, input.text)

  }
}
