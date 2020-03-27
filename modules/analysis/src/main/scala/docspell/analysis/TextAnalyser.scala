package docspell.analysis

import cats.effect._
import cats.implicits._
import docspell.analysis.contact.Contact
import docspell.analysis.date.DateFind
import docspell.analysis.nlp.StanfordNerClassifier
import docspell.common._

trait TextAnalyser[F[_]] {

  def annotate(logger: Logger[F], lang: Language, text: String): F[TextAnalyser.Result]

}
object TextAnalyser {

  case class Result(labels: Vector[NerLabel], dates: Vector[NerDateLabel]) {

    def all: Vector[NerLabel] =
      labels ++ dates.map(dl => dl.label.copy(label = dl.date.toString))
  }

  def create[F[_]: Sync](cfg: TextAnalysisConfig): Resource[F, TextAnalyser[F]] =
    Resource.pure[F, TextAnalyser[F]](new TextAnalyser[F] {
      def annotate(
          logger: Logger[F],
          lang: Language,
          text: String
      ): F[TextAnalyser.Result] =
        for {
          input <- textLimit(logger, text)
          tags0 <- stanfordNer(lang, input)
          tags1 <- contactNer(input)
          dates <- dateNer(lang, input)
          list  = tags0 ++ tags1
          spans = NerLabelSpan.build(list)
        } yield Result(spans ++ list, dates)

      private def textLimit(logger: Logger[F], text: String): F[String] =
        if (text.length <= cfg.maxLength) text.pure[F]
        else
          logger.info(
            s"The text to analyse is larger than limit (${text.length} > ${cfg.maxLength})." +
              s" Analysing only first ${cfg.maxLength} characters."
          ) *> text.take(cfg.maxLength).pure[F]

      private def stanfordNer(lang: Language, text: String): F[Vector[NerLabel]] =
        Sync[F].delay {
          StanfordNerClassifier.nerAnnotate(lang)(text)
        }

      private def contactNer(text: String): F[Vector[NerLabel]] = Sync[F].delay {
        Contact.annotate(text)
      }

      private def dateNer(lang: Language, text: String): F[Vector[NerDateLabel]] =
        Sync[F].delay {
          DateFind.findDates(text, lang).toVector
        }
    })

}
