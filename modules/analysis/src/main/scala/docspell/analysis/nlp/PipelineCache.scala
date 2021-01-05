package docspell.analysis.nlp

import cats.Applicative
import cats.effect._
import cats.effect.concurrent.Ref
import cats.implicits._

import docspell.common._

import edu.stanford.nlp.pipeline.StanfordCoreNLP
import org.log4s.getLogger
import scala.concurrent.duration._
import cats.data.OptionT

/** Creating the StanfordCoreNLP pipeline is quite expensive as it
  * involves IO and initializing large objects.
  *
  * Therefore, the instances are cached, because they are thread-safe.
  *
  * **This is an internal API**
  */
trait PipelineCache[F[_]] {

  def obtain(key: String, settings: StanfordNerSettings): F[StanfordCoreNLP]

}

object PipelineCache {
  private[this] val logger = getLogger

  def none[F[_]: Applicative]: PipelineCache[F] =
    new PipelineCache[F] {
      def obtain(ignored: String, settings: StanfordNerSettings): F[StanfordCoreNLP] =
        makeClassifier(settings).pure[F]
    }

  def apply[F[_]: Concurrent: Timer](): F[PipelineCache[F]] =
    for {
      data     <- Ref.of(Map.empty[String, Entry])
      counter  <- Ref.of(Long.MinValue)
      cleaning <- Ref.of(false)
    } yield new Impl[F](data, counter, cleaning): PipelineCache[F]

  final private class Impl[F[_]](
      data: Ref[F, Map[String, Entry]],
      counter: Ref[F, Long],
      cleaningProgress: Ref[F, Boolean]
  )(implicit T: Timer[F], F: Concurrent[F])
      extends PipelineCache[F] {

    private[this] val clearInterval = 1.minute
    private[this] val log           = Logger.log4s(logger)

    def obtain(key: String, settings: StanfordNerSettings): F[StanfordCoreNLP] =
      for {
        id  <- makeSettingsId(settings)
        nlp <- data.modify(cache => getOrCreate(key, id, cache, settings))
        _   <- scheduleClearPipeline
      } yield nlp

    private def scheduleClearPipeline: F[Unit] =
      (for {
        cnt <- OptionT(counter.tryModify(n => (n + 1, n + 1)))
        free <- OptionT.liftF(cleaningProgress.access.flatMap { case (b, setter) =>
          if (b) false.pure[F]
          else setter(true)
        })
        _ <- OptionT.liftF(
          if (free)
            F.start(
              T.sleep(clearInterval) *> cleaningProgress.set(false) *> clearStale(cnt)
            )
          else ().pure[F]
        )
      } yield ()).getOrElse(())

    private def clearStale(n: Long): F[Unit] =
      log.debug("Attempting to clear stanford nlp pipeline cache to free memory") *>
        counter.get.flatMap(x =>
          if (x == n) clearAll
          else
            log.debug(
              "Don't clear yet, as it has been used in between"
            ) *> scheduleClearPipeline
        )

    private def clearAll: F[Unit] =
      log.info("Clearing stanford nlp pipeline cache now!") *>
        data.set(Map.empty) *> Sync[F].delay {
          // turns out that everything is cached in a static map
          StanfordCoreNLP.clearAnnotatorPool()
          System.gc();
        }

    private def getOrCreate(
        key: String,
        id: String,
        cache: Map[String, Entry],
        settings: StanfordNerSettings
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

    private def makeSettingsId(settings: StanfordNerSettings): F[String] = {
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


  private def makeClassifier(settings: StanfordNerSettings): StanfordCoreNLP = {
    logger.info(s"Creating ${settings.lang.name} Stanford NLP NER classifier...")
    new StanfordCoreNLP(Properties.forSettings(settings))
  }

  private case class Entry(id: String, value: StanfordCoreNLP)
}
