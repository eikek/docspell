/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import java.util.concurrent.atomic.AtomicInteger

import cats.effect.IO
import fs2.io.file.Path

import docspell.common.LenientUri
import docspell.common.exec.Env
import docspell.logging.{Logger, TestLoggingConfig}

import munit._

class AddonRunnerTest extends CatsEffectSuite with TestLoggingConfig {

  val logger = docspell.logging.getLogger[IO]

  val dummyContext = Context(
    addon = AddonRef(AddonArchive(LenientUri.unsafe("http://test"), "", ""), ""),
    meta = AddonMeta.empty("test", "1.0"),
    baseDir = Path(""),
    addonDir = Path(""),
    outputDir = Path(""),
    cacheDir = Path("")
  )

  test("firstSuccessful must stop on first success") {
    val counter = new AtomicInteger(0)
    val runner = new MockRunner(IO(counter.incrementAndGet()).void)
    val r = AddonRunner.firstSuccessful(runner, runner, runner)
    for {
      _ <- r.run(logger, Env.empty, dummyContext)
      _ = assertEquals(counter.get(), 1)
    } yield ()
  }

  test("firstSuccessful must try with next on error") {
    val counter = new AtomicInteger(0)
    val fail = AddonRunner.failWith[IO]("failed")
    val runner: AddonRunner[IO] = new MockRunner(IO(counter.incrementAndGet()).void)
    val r = AddonRunner.firstSuccessful(fail, runner, runner)
    for {
      _ <- r.run(logger, Env.empty, dummyContext)
      _ = assertEquals(counter.get(), 1)
    } yield ()
  }

  test("do not retry on decoding errors") {
    val counter = new AtomicInteger(0)
    val fail = AddonRunner.pure[IO](AddonResult.decodingError("Decoding failed"))
    val increment: AddonRunner[IO] = new MockRunner(IO(counter.incrementAndGet()).void)

    val r = AddonRunner.firstSuccessful(fail, increment, increment)
    for {
      _ <- r.run(logger, Env.empty, dummyContext)
      _ = assertEquals(counter.get(), 0)
    } yield ()
  }

  test("try on errors but stop on decoding error") {
    val counter = new AtomicInteger(0)
    val decodeFail = AddonRunner.pure[IO](AddonResult.decodingError("Decoding failed"))
    val incrementFail =
      new MockRunner(IO(counter.incrementAndGet()).void)
        .as(AddonResult.executionFailed(new Exception("fail")))
    val increment: AddonRunner[IO] = new MockRunner(IO(counter.incrementAndGet()).void)

    val r = AddonRunner.firstSuccessful(
      incrementFail,
      incrementFail,
      decodeFail,
      increment,
      increment
    )
    for {
      _ <- r.run(logger, Env.empty, dummyContext)
      _ = assertEquals(counter.get(), 2)
    } yield ()
  }

  final class MockRunner(run: IO[Unit], result: AddonResult = AddonResult.empty)
      extends AddonRunner[IO] {
    val runnerType = Nil
    def run(
        logger: Logger[IO],
        env: Env,
        ctx: Context
    ) = run.as(result)

    def as(r: AddonResult) = new MockRunner(run, r)
  }
}
