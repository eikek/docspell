package docspell.common

import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.{Executors, ThreadFactory}
import cats.effect._
import scala.concurrent._

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

  def executorResource[F[_]: Sync](
      c: => ExecutionContextExecutorService
  ): Resource[F, ExecutionContextExecutorService] =
    Resource.make(Sync[F].delay(c))(ec => Sync[F].delay(ec.shutdown))

  def cached[F[_]: Sync](tf: ThreadFactory): Resource[F, ExecutionContextExecutorService] =
    executorResource(
      ExecutionContext.fromExecutorService(Executors.newCachedThreadPool(tf))
    )

  def fixed[F[_]: Sync](n: Int, tf: ThreadFactory): Resource[F, ExecutionContextExecutorService] =
    executorResource(ExecutionContext.fromExecutorService(Executors.newFixedThreadPool(n, tf)))
}
