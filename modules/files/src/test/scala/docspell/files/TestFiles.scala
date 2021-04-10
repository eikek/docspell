package docspell.files

import scala.concurrent.ExecutionContext

import cats.effect.{Blocker, IO}
import fs2.Stream

object TestFiles {
  val blocker     = Blocker.liftExecutionContext(ExecutionContext.global)
  implicit val CS = IO.contextShift(ExecutionContext.global)

  val letterSourceDE: Stream[IO, Byte] =
    ExampleFiles.letter_de_pdf
      .readURL[IO](8 * 1024, blocker)

  val letterSourceEN: Stream[IO, Byte] =
    ExampleFiles.letter_en_pdf
      .readURL[IO](8 * 1024, blocker)

  lazy val letterDEText =
    ExampleFiles.letter_de_txt
      .readText[IO](8 * 1024, blocker)
      .unsafeRunSync()

  lazy val letterENText =
    ExampleFiles.letter_en_txt
      .readText[IO](8 * 1024, blocker)
      .unsafeRunSync()
}
