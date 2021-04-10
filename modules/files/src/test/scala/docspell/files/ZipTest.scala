package docspell.files

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.implicits._

import docspell.common.Glob

import munit._

class ZipTest extends FunSuite {

  val blocker     = Blocker.liftExecutionContext(ExecutionContext.global)
  implicit val CS = IO.contextShift(ExecutionContext.global)

  test("unzip") {
    val zipFile = ExampleFiles.letters_zip.readURL[IO](8192, blocker)
    val uncomp  = zipFile.through(Zip.unzip(8192, blocker, Glob.all))

    uncomp
      .evalMap { entry =>
        val x = entry.data.map(_ => 1).foldMonoid.compile.lastOrError
        x.map { size =>
          if (entry.name.endsWith(".pdf")) {
            assertEquals(entry.name, "letter-de.pdf")
            assertEquals(size, 34815)
          } else {
            assertEquals(entry.name, "letter-en.txt")
            assertEquals(size, 1131)
          }
        }
      }
      .compile
      .drain
      .unsafeRunSync()
  }
}
