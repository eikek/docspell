/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.classifier

import java.nio.file.Paths

import cats.data.Kleisli
import cats.data.NonEmptyList
import cats.effect._
import cats.effect.unsafe.implicits.global
import fs2.Stream
import fs2.io.file.Files

import docspell.analysis.classifier.TextClassifier.Data
import docspell.common._

import munit._

class StanfordTextClassifierSuite extends FunSuite {
  val logger = docspell.logging.getLogger[IO]

  test("learn from data") {
    val cfg = TextClassifierConfig(File.path(Paths.get("target")), NonEmptyList.of(Map()))

    val data =
      Stream
        .emit(Data("invoice", "n", "this is your invoice   total $421"))
        .repeat
        .take(10)
        .zip(
          Stream
            .emit(Data("receipt", "n", "shopping receipt cheese cake bar"))
            .repeat
            .take(10)
        )
        .flatMap { case (a, b) =>
          Stream.emits(Seq(a, b))
        }
        .covary[IO]

    val modelExists = {
      val classifier = new StanfordTextClassifier[IO](cfg)
      classifier.trainClassifier[Boolean](logger, data)(
        Kleisli(result => File.existsNonEmpty[IO](result.model))
      )
    }
    assertEquals(modelExists.unsafeRunSync(), true)
  }

  test("run classifier") {
    val cfg = TextClassifierConfig(File.path(Paths.get("target")), NonEmptyList.of(Map()))
    val things = File.withTempDir[IO](File.path(Paths.get("target")), "testcls")

    things
      .use { dir =>
        val classifier = new StanfordTextClassifier[IO](cfg)

        val modelFile = dir.resolve("test.ser.gz")
        for {
          _ <-
            LenientUri
              .fromJava(getClass.getResource("/test.ser.gz"))
              .readURL[IO](4096)
              .through(Files[IO].writeAll(modelFile))
              .compile
              .drain
          model = ClassifierModel(modelFile)
          cat <- classifier.classify(logger, model, "there is receipt always")
          _ = assertEquals(cat, Some("receipt"))
        } yield ()
      }
      .unsafeRunSync()
  }
}
