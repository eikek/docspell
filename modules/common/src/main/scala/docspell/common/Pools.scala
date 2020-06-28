package docspell.common

import scala.concurrent.ExecutionContext

import cats.effect._

/** Captures thread pools to use in an application.
  */
case class Pools(
    connectEC: ExecutionContext,
    httpClientEC: ExecutionContext,
    blocker: Blocker,
    restEC: ExecutionContext
)
