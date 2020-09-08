package docspell.analysis.nlp

import minitest._
import cats.effect._
import scala.concurrent.ExecutionContext
import java.nio.file.Paths
import cats.data.NonEmptyList
import docspell.common._
import fs2.Stream
import cats.data.Kleisli
import TextClassifier.Data

object StanfordTextClassifierSuite extends SimpleTestSuite {
  val logger = Logger.log4s[IO](org.log4s.getLogger)

  implicit val CS = IO.contextShift(ExecutionContext.global)

  test("learn from data") {
    val cfg = TextClassifierConfig(Paths.get("target"), NonEmptyList.of(Map()))

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
        .flatMap({ case (a, b) =>
          Stream.emits(Seq(a, b))
        })
        .covary[IO]

    val modelExists =
      Blocker[IO].use { blocker =>
        val classifier = new StanfordTextClassifier[IO](cfg, blocker)
        classifier.trainClassifier[Boolean](logger, data)(
          Kleisli(result => File.existsNonEmpty[IO](result.model))
        )
      }
    assertEquals(modelExists.unsafeRunSync(), true)
  }

  test("run classifier") {
    val cfg = TextClassifierConfig(Paths.get("target"), NonEmptyList.of(Map()))
    val things = for {
      dir     <- File.withTempDir[IO](Paths.get("target"), "testcls")
      blocker <- Blocker[IO]
    } yield (dir, blocker)

    things
      .use { case (dir, blocker) =>
        val classifier = new StanfordTextClassifier[IO](cfg, blocker)

        val modelFile = dir.resolve("test.ser.gz")
        for {
          _ <-
            LenientUri
              .fromJava(getClass.getResource("/test.ser.gz"))
              .readURL[IO](4096, blocker)
              .through(fs2.io.file.writeAll(modelFile, blocker))
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
