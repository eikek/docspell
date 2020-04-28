package docspell.common

import cats.effect._
import scala.concurrent.ExecutionContext

/** Captures thread pools to use in an application.
  */
case class Pools(
    connectEC: ExecutionContext,
    httpClientEC: ExecutionContext,
    blocker: Blocker,
    restEC: ExecutionContext
)
