package docspell.files

import cats.effect._
import cats.effect.unsafe.implicits.global
import cats.implicits._

import docspell.common.Glob

import munit._

class ZipTest extends FunSuite {

  test("unzip") {
    val zipFile = ExampleFiles.letters_zip.readURL[IO](8192)
    val uncomp  = zipFile.through(Zip.unzip(8192, Glob.all))

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
