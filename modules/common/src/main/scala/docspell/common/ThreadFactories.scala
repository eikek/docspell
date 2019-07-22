package docspell.common

import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.{Executors, ThreadFactory}

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

}
