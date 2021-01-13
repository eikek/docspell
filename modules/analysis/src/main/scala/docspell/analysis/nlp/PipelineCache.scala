package docspell.analysis.nlp

import scala.concurrent.duration.{Duration => _, _}
import cats.Applicative
import cats.data.Kleisli
import cats.effect._
import cats.effect.concurrent.Ref
import cats.implicits._
import docspell.common._
import org.log4s.getLogger

/** Creating the StanfordCoreNLP pipeline is quite expensive as it
  * involves IO and initializing large objects.
  *
  * Therefore, the instances are cached, because they are thread-safe.
  *
  * **This is an internal API**
  */
trait PipelineCache[F[_], A] {

  def obtain(key: String, settings: StanfordNerSettings): Resource[F, A]

}

object PipelineCache {
  private[this] val logger = getLogger

  def none[F[_]: Applicative, A](
      creator: Kleisli[F, StanfordNerSettings, A]
  ): PipelineCache[F, A] =
    new PipelineCache[F, A] {
      def obtain(
          ignored: String,
          settings: StanfordNerSettings
      ): Resource[F, A] =
        Resource.liftF(creator.run(settings))
    }

  def apply[F[_]: Concurrent: Timer, A](clearInterval: Duration)(
      creator: StanfordNerSettings => A,
      release: F[Unit]
  ): F[PipelineCache[F, A]] =
    for {
      data       <- Ref.of(Map.empty[String, Entry[A]])
      cacheClear <- CacheClearing.create(data, clearInterval, release)
    } yield new Impl[F, A](data, creator, cacheClear)

  final private class Impl[F[_]: Sync, A](
      data: Ref[F, Map[String, Entry[A]]],
      creator: StanfordNerSettings => A,
      cacheClear: CacheClearing[F]
  ) extends PipelineCache[F, A] {

    def obtain(key: String, settings: StanfordNerSettings): Resource[F, A] =
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
        cache: Map[String, Entry[A]],
        settings: StanfordNerSettings,
        creator: StanfordNerSettings => A
    ): (Map[String, Entry[A]], A) =
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
