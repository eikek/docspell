package docspell.common

import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.{Executors, ThreadFactory}
import cats.effect._
import scala.concurrent._
import java.util.concurrent.ForkJoinPool
import java.util.concurrent.ForkJoinPool.ForkJoinWorkerThreadFactory
import java.util.concurrent.ForkJoinWorkerThread

object ThreadFactories {

  def ofName(prefix: String): ThreadFactory =
    new ThreadFactory {

      val counter = new AtomicLong(0)

      override def newThread(r: Runnable): Thread = {
        val t = Executors.defaultThreadFactory().newThread(r)
        t.setName(s"$prefix-${counter.getAndIncrement()}")
        t
      }
    }

  def ofNameFJ(prefix: String): ForkJoinWorkerThreadFactory =
    new ForkJoinWorkerThreadFactory {
      val tf      = ForkJoinPool.defaultForkJoinWorkerThreadFactory
      val counter = new AtomicLong(0)

      def newThread(pool: ForkJoinPool): ForkJoinWorkerThread = {
        val t = tf.newThread(pool)
        t.setName(s"$prefix-${counter.getAndIncrement()}")
        t
      }
    }

  def executorResource[F[_]: Sync](
      c: => ExecutionContextExecutorService
  ): Resource[F, ExecutionContextExecutorService] =
    Resource.make(Sync[F].delay(c))(ec => Sync[F].delay(ec.shutdown))

  def cached[F[_]: Sync](
      tf: ThreadFactory
  ): Resource[F, ExecutionContextExecutorService] =
    executorResource(
      ExecutionContext.fromExecutorService(Executors.newCachedThreadPool(tf))
    )

  def fixed[F[_]: Sync](
      n: Int,
      tf: ThreadFactory
  ): Resource[F, ExecutionContextExecutorService] =
    executorResource(
      ExecutionContext.fromExecutorService(Executors.newFixedThreadPool(n, tf))
    )

  def workSteal[F[_]: Sync](
      n: Int,
      tf: ForkJoinWorkerThreadFactory
  ): Resource[F, ExecutionContextExecutorService] =
    executorResource(
      ExecutionContext.fromExecutorService(
        new ForkJoinPool(n, tf, null, true)
      )
    )

  def workSteal[F[_]: Sync](
      tf: ForkJoinWorkerThreadFactory
  ): Resource[F, ExecutionContextExecutorService] =
    workSteal[F](Runtime.getRuntime().availableProcessors() + 1, tf)
}
