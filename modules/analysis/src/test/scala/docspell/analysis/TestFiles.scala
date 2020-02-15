package docspell.analysis

import cats.effect.{Blocker, IO}
import docspell.files._

import scala.concurrent.ExecutionContext

object TestFiles {
  val blocker     = Blocker.liftExecutionContext(ExecutionContext.global)
  implicit val CS = IO.contextShift(ExecutionContext.global)

  lazy val letterDEText =
    ExampleFiles.letter_de_txt
      .readText[IO](16 * 1024, blocker)
      .unsafeRunSync

  lazy val letterENText =
    ExampleFiles.letter_en_txt
      .readText[IO](16 * 1024, blocker)
      .unsafeRunSync
}
