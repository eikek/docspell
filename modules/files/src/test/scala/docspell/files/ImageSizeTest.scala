package docspell.files

import cats.implicits._
import cats.effect.{Blocker, IO}
import minitest.SimpleTestSuite

import scala.concurrent.ExecutionContext
import scala.util.Using

object ImageSizeTest extends SimpleTestSuite {
  val blocker     = Blocker.liftExecutionContext(ExecutionContext.global)
  implicit val CS = IO.contextShift(ExecutionContext.global)

  //tiff files are not supported on the jdk by default
  //requires an external library
  val files = List(
    ExampleFiles.camera_letter_en_jpg -> Dimension(1695, 2378),
    ExampleFiles.camera_letter_en_png -> Dimension(1695, 2378),
//    ExampleFiles.camera_letter_en_tiff -> Dimension(1695, 2378),
    ExampleFiles.scanner_jfif_jpg    -> Dimension(2480, 3514),
    ExampleFiles.bombs_20K_gray_jpeg -> Dimension(20000, 20000),
    ExampleFiles.bombs_20K_gray_png  -> Dimension(20000, 20000),
    ExampleFiles.bombs_20K_rgb_jpeg  -> Dimension(20000, 20000),
    ExampleFiles.bombs_20K_rgb_png   -> Dimension(20000, 20000)
  )

  test("get sizes from input-stream") {
    files.foreach { case (uri, expect) =>
      val url = uri.toJavaUrl.fold(sys.error, identity)
      Using.resource(url.openStream()) { in =>
        val dim = ImageSize.get(in)
        assertEquals(dim, expect.some)
      }
    }
  }

  test("get sizes from stream") {
    files.foreach { case (uri, expect) =>
      val stream = uri.readURL[IO](8192, blocker)
      val dim    = ImageSize.get(stream).unsafeRunSync()
      assertEquals(dim, expect.some)
    }
  }
}
