package docspell.analysis.nlp

import cats.Applicative
import cats.effect._
import cats.effect.concurrent.Ref
import cats.implicits._

import docspell.common._

import edu.stanford.nlp.pipeline.StanfordCoreNLP
import org.log4s.getLogger

/** Creating the StanfordCoreNLP pipeline is quite expensive as it
  * involves IO and initializing large objects.
  *
  * Therefore, the instances are cached, because they are thread-safe.
  *
  * **This is an internal API**
  */
trait PipelineCache[F[_]] {

  def obtain(key: String, settings: StanfordSettings): F[StanfordCoreNLP]

}

object PipelineCache {
  private[this] val logger = getLogger

  def none[F[_]: Applicative]: PipelineCache[F] =
    new PipelineCache[F] {
      def obtain(ignored: String, settings: StanfordSettings): F[StanfordCoreNLP] =
        makeClassifier(settings).pure[F]
    }

  def apply[F[_]: Sync](): F[PipelineCache[F]] =
    Ref.of(Map.empty[String, Entry]).map(data => (new Impl[F](data): PipelineCache[F]))

  final private class Impl[F[_]: Sync](data: Ref[F, Map[String, Entry]])
      extends PipelineCache[F] {

    def obtain(key: String, settings: StanfordSettings): F[StanfordCoreNLP] =
      for {
        id  <- makeSettingsId(settings)
        nlp <- data.modify(cache => getOrCreate(key, id, cache, settings))
      } yield nlp

    private def getOrCreate(
        key: String,
        id: String,
        cache: Map[String, Entry],
        settings: StanfordSettings
    ): (Map[String, Entry], StanfordCoreNLP) =
      cache.get(key) match {
        case Some(entry) =>
          if (entry.id == id) (cache, entry.value)
          else {
            logger.info(
              s"StanfordNLP settings changed for key $key. Creating new classifier"
            )
            val nlp = makeClassifier(settings)
            val e   = Entry(id, nlp)
            (cache.updated(key, e), nlp)
          }

        case None =>
          val nlp = makeClassifier(settings)
          val e   = Entry(id, nlp)
          (cache.updated(key, e), nlp)
      }

    private def makeSettingsId(settings: StanfordSettings): F[String] = {
      val base = settings.copy(regexNer = None).toString
      val size: F[Long] =
        settings.regexNer match {
          case Some(p) =>
            File.size(p)
          case None =>
            0L.pure[F]
        }
      size.map(len => s"$base-$len")
    }

  }
  private def makeClassifier(settings: StanfordSettings): StanfordCoreNLP = {
    logger.info(s"Creating ${settings.lang.name} Stanford NLP NER classifier...")
    new StanfordCoreNLP(Properties.forSettings(settings))
  }

  private case class Entry(id: String, value: StanfordCoreNLP)
}
