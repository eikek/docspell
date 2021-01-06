package docspell.analysis.nlp

import scala.concurrent.duration.{Duration => _, _}

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

  def obtain(key: String, settings: StanfordNerSettings): Resource[F, StanfordCoreNLP]

}

object PipelineCache {
  private[this] val logger = getLogger

  def none[F[_]: Applicative]: PipelineCache[F] =
    new PipelineCache[F] {
      def obtain(
          ignored: String,
          settings: StanfordNerSettings
      ): Resource[F, StanfordCoreNLP] =
        Resource.liftF(makeClassifier(settings).pure[F])
    }

  def apply[F[_]: Concurrent: Timer](clearInterval: Duration): F[PipelineCache[F]] =
    for {
      data       <- Ref.of(Map.empty[String, Entry])
      cacheClear <- CacheClearing.create(data, clearInterval)
    } yield new Impl[F](data, cacheClear)

  final private class Impl[F[_]: Sync](
      data: Ref[F, Map[String, Entry]],
      cacheClear: CacheClearing[F]
  ) extends PipelineCache[F] {

    def obtain(key: String, settings: StanfordNerSettings): Resource[F, StanfordCoreNLP] =
      for {
        _   <- cacheClear.withCache
        id  <- Resource.liftF(makeSettingsId(settings))
        nlp <- Resource.liftF(data.modify(cache => getOrCreate(key, id, cache, settings)))
      } yield nlp

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

  trait CacheClearing[F[_]] {
    def withCache: Resource[F, Unit]
  }

  object CacheClearing {
    def none[F[_]: Applicative]: CacheClearing[F] =
      new CacheClearing[F] {
        def withCache: Resource[F, Unit] =
          Resource.pure[F, Unit](())
      }

    def create[F[_]: Concurrent: Timer](
        data: Ref[F, Map[String, Entry]],
        interval: Duration
    ): F[CacheClearing[F]] =
      for {
        counter  <- Ref.of(0L)
        cleaning <- Ref.of(None: Option[Fiber[F, Unit]])
        log = Logger.log4s(logger)
        result <-
          if (interval.millis <= 0)
            log
              .info("Disable clearing StanfordNLP cache, due to config setting")
              .map(_ => none[F])
          else
            log
              .info(s"Clearing StanfordNLP cache after $interval idle time")
              .map(_ =>
                new CacheClearingImpl[F](data, counter, cleaning, interval.toScala)
              )
      } yield result
  }

  final private class CacheClearingImpl[F[_]](
      data: Ref[F, Map[String, Entry]],
      counter: Ref[F, Long],
      cleaningFiber: Ref[F, Option[Fiber[F, Unit]]],
      clearInterval: FiniteDuration
  )(implicit T: Timer[F], F: Concurrent[F])
      extends CacheClearing[F] {
    private[this] val log = Logger.log4s[F](logger)

    def withCache: Resource[F, Unit] =
      Resource.make(counter.update(_ + 1))(_ =>
        counter.updateAndGet(_ - 1).flatMap(n => scheduleClearPipeline(n))
      )

    def scheduleClearPipeline(cnt: Long): F[Unit] =
      if (cnt > 0) cancelClear
      else cancelClear *> clearAllLater.flatMap(fiber => cleaningFiber.set(fiber.some))

    private def cancelClear: F[Unit] =
      cleaningFiber.getAndSet(None).flatMap {
        case Some(fiber) => fiber.cancel *> logDontClear
        case None        => ().pure[F]
      }

    private def clearAllLater: F[Fiber[F, Unit]] =
      F.start(T.sleep(clearInterval) *> clearAll)

    private def logDontClear: F[Unit] =
      log.info("Cancel stanford cache clearing, as it has been used in between.")

    def clearAll: F[Unit] =
      log.info("Clearing stanford nlp cache now!") *>
        data.set(Map.empty) *> Sync[F].delay {
          // turns out that everything is cached in a static map
          StanfordCoreNLP.clearAnnotatorPool()
          System.gc();
        }
  }

  private def makeClassifier(settings: StanfordNerSettings): StanfordCoreNLP = {
    logger.info(s"Creating ${settings.lang.name} Stanford NLP NER classifier...")
    new StanfordCoreNLP(Properties.forSettings(settings))
  }

  private case class Entry(id: String, value: StanfordCoreNLP)
}
