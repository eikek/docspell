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
    // sleep keeps pipes open without closing them — same shape as a hung weasyprint:
    // Process.waitFor(timeout) returns, then joining log drains would deadlock forever
    // unless the child is destroyed first.
    val cmd = SysCmd("sleep", "30").withTimeout(Duration.millis(500))
    val started = System.nanoTime()

    SysExec(cmd, logger)
      .flatMap(_.logOutputs(logger, "sleep"))
      .use(_.waitFor())
      .attempt
      .map { result =>
        val elapsed = (System.nanoTime() - started).nanos
        assert(result.left.exists(_.isInstanceOf[TimeoutException]), clue = result)
        assert(
          result.left.exists(_.getMessage.contains("Timed out after: 500 ms")),
          clue = result
        )
        // Must not hang joining log fibers after the command timeout.
        assert(elapsed < 5.seconds, clue = elapsed)
      }
  }

  test("waitFor timeout works when child keeps writing to stderr") {
    // Closer to a noisy converter: background log fibers stay busy on open pipes.
    val cmd = SysCmd(
      "sh",
      "-c",
      "while true; do echo tick >&2; sleep 0.2; done"
    ).withTimeout(Duration.millis(800))
    val started = System.nanoTime()

    SysExec(cmd, logger)
      .flatMap(_.logOutputs(logger, "noisy"))
      .use(_.waitFor())
      .attempt
      .map { result =>
        val elapsed = (System.nanoTime() - started).nanos
        assert(result.left.exists(_.isInstanceOf[TimeoutException]), clue = result)
        assert(elapsed < 5.seconds, clue = elapsed)
      }
  }
}
