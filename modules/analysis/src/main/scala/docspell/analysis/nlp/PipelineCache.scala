/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.nlp

import scala.concurrent.duration.{Duration => _, _}

import cats.effect.Ref
import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.analysis.NlpSettings
import docspell.common._
import docspell.common.util.File

/** Creating the StanfordCoreNLP pipeline is quite expensive as it involves IO and
  * initializing large objects.
  *
  * Therefore, the instances are cached, because they are thread-safe.
  *
  * **This is an internal API**
  */
trait PipelineCache[F[_]] {

  def obtain(key: String, settings: NlpSettings): Resource[F, Annotator[F]]

}

object PipelineCache {
  private[this] val logger = docspell.logging.unsafeLogger

  def apply[F[_]: Async: Files](clearInterval: Duration)(
      creator: NlpSettings => Annotator[F],
      release: F[Unit]
  ): F[PipelineCache[F]] = {
    val log = docspell.logging.getLogger[F]
    for {
      data <- Ref.of(Map.empty[String, Entry[Annotator[F]]])
      cacheClear <- CacheClearing.create(data, clearInterval, release)
      _ <- log.info("Creating nlp pipeline cache")
    } yield new Impl[F](data, creator, cacheClear)
  }

  final private class Impl[F[_]: Async: Files](
      data: Ref[F, Map[String, Entry[Annotator[F]]]],
      creator: NlpSettings => Annotator[F],
      cacheClear: CacheClearing[F]
  ) extends PipelineCache[F] {

    def obtain(key: String, settings: NlpSettings): Resource[F, Annotator[F]] =
      for {
        _ <- cacheClear.withCache
        id <- Resource.eval(makeSettingsId(settings))
        nlp <- Resource.eval(
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
            val e = Entry(id, nlp)
            (cache.updated(key, e), nlp)
          }

        case None =>
          val nlp = creator(settings)
          val e = Entry(id, nlp)
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
    def none[F[_]]: CacheClearing[F] =
      new CacheClearing[F] {
        def withCache: Resource[F, Unit] =
          Resource.pure[F, Unit](())
      }

    def create[F[_]: Async, A](
        data: Ref[F, Map[String, Entry[A]]],
        interval: Duration,
        release: F[Unit]
    ): F[CacheClearing[F]] =
      for {
        counter <- Ref.of(0L)
        cleaning <- Ref.of(None: Option[Fiber[F, Throwable, Unit]])
        log = docspell.logging.getLogger[F]
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
      cleaningFiber: Ref[F, Option[Fiber[F, Throwable, Unit]]],
      clearInterval: FiniteDuration,
      release: F[Unit]
  )(implicit F: Async[F])
      extends CacheClearing[F] {
    private[this] val log = docspell.logging.getLogger[F]

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

    private def clearAllLater: F[Fiber[F, Throwable, Unit]] =
      F.start(F.sleep(clearInterval) *> clearAll)

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
