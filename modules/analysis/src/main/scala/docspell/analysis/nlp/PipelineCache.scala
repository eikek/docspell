package docspell.analysis.nlp

import scala.concurrent.duration.{Duration => _, _}

import cats.Applicative
import cats.effect._
import cats.effect.concurrent.Ref
import cats.implicits._

import docspell.analysis.NlpSettings
import docspell.common._

import org.log4s.getLogger

/** Creating the StanfordCoreNLP pipeline is quite expensive as it
  * involves IO and initializing large objects.
  *
  * Therefore, the instances are cached, because they are thread-safe.
  *
  * **This is an internal API**
  */
trait PipelineCache[F[_]] {

  def obtain(key: String, settings: NlpSettings): Resource[F, Annotator[F]]

}

object PipelineCache {
  private[this] val logger = getLogger

  def apply[F[_]: Concurrent: Timer](clearInterval: Duration)(
      creator: NlpSettings => Annotator[F],
      release: F[Unit]
  ): F[PipelineCache[F]] =
    for {
      data       <- Ref.of(Map.empty[String, Entry[Annotator[F]]])
      cacheClear <- CacheClearing.create(data, clearInterval, release)
      _          <- Logger.log4s(logger).info("Creating nlp pipeline cache")
    } yield new Impl[F](data, creator, cacheClear)

  final private class Impl[F[_]: Sync](
      data: Ref[F, Map[String, Entry[Annotator[F]]]],
      creator: NlpSettings => Annotator[F],
      cacheClear: CacheClearing[F]
  ) extends PipelineCache[F] {

    def obtain(key: String, settings: NlpSettings): Resource[F, Annotator[F]] =
      for {
        _  <- cacheClear.withCache
        id <- Resource.liftF(makeSettingsId(settings))
        nlp <- Resource.liftF(
          data.modify(cache => getOrCreate(key, id, cache, settings, creator))
        )
      } yield nlp

    private def getOrCreate(
        key: String,
        id: String,
        cache: Map[String, Entry[Annotator[F]]],
        settings: NlpSettings,
        creator: NlpSettings => Annotator[F]
    ): (Map[String, Entry[Annotator[F]]], Annotator[F]) =
      cache.get(key) match {
        case Some(entry) =>
          if (entry.id == id) (cache, entry.value)
          else {
            logger.info(
              s"StanfordNLP settings changed for key $key. Creating new classifier"
            )
            val nlp = creator(settings)
            val e   = Entry(id, nlp)
            (cache.updated(key, e), nlp)
          }

        case None =>
          val nlp = creator(settings)
          val e   = Entry(id, nlp)
          (cache.updated(key, e), nlp)
      }

    private def makeSettingsId(settings: NlpSettings): F[String] = {
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

    def create[F[_]: Concurrent: Timer, A](
        data: Ref[F, Map[String, Entry[A]]],
        interval: Duration,
        release: F[Unit]
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
                new CacheClearingImpl[F, A](
                  data,
                  counter,
                  cleaning,
                  interval.toScala,
                  release
                )
              )
      } yield result
  }

  final private class CacheClearingImpl[F[_], A](
      data: Ref[F, Map[String, Entry[A]]],
      counter: Ref[F, Long],
      cleaningFiber: Ref[F, Option[Fiber[F, Unit]]],
      clearInterval: FiniteDuration,
      release: F[Unit]
  )(implicit T: Timer[F], F: Concurrent[F])
      extends CacheClearing[F] {
    private[this] val log = Logger.log4s[F](logger)

    def withCache: Resource[F, Unit] =
      Resource.make(counter.update(_ + 1) *> cancelClear)(_ =>
        counter.updateAndGet(_ - 1).flatMap(n => scheduleClearPipeline(n))
      )

    def scheduleClearPipeline(cnt: Long): F[Unit] =
      if (cnt > 0) ().pure[F]
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
        data.set(Map.empty) *> release *> Sync[F].delay {
          System.gc();
        }
  }

  private case class Entry[A](id: String, value: A)
}
