/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

import scala.concurrent.TimeoutException
import scala.concurrent.duration._

import cats.effect._

import docspell.common.Duration
import docspell.logging.TestLoggingConfig

import munit.CatsEffectSuite

class SysExecTest extends CatsEffectSuite with TestLoggingConfig {
  val logger = docspell.logging.Logger.offF[IO]

  test("waitFor raises timeout while logOutputs are active") {
    val cmd = SysCmd("sleep", "30").withTimeout(Duration.millis(500))
    val started = System.nanoTime()

    SysExec(cmd, logger)
      .flatMap(_.logOutputs(logger, "sleep"))
      .use(_.waitFor())
      .attempt
      .map { result =>
        val elapsed = (System.nanoTime() - started).nanos
        assert(result.left.exists(_.isInstanceOf[TimeoutException]), clue = result)
        // Must not hang joining log fibers after the command timeout.
        assert(elapsed < 10.seconds, clue = elapsed)
      }
  }
}
