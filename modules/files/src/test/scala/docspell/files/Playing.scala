package docspell.files

import cats.effect.{Blocker, ExitCode, IO, IOApp}
import docspell.common.MimeTypeHint

import scala.concurrent.ExecutionContext

object Playing extends IOApp {
  val blocker = Blocker.liftExecutionContext(ExecutionContext.global)

  def run(args: List[String]): IO[ExitCode] = IO {
    //val ods = ExampleFiles.examples_sample_ods.readURL[IO](8192, blocker)
    //val odt = ExampleFiles.examples_sample_odt.readURL[IO](8192, blocker)
    val rtf = ExampleFiles.examples_sample_rtf.readURL[IO](8192, blocker)

    val x = for {
      odsm1 <- TikaMimetype
        .detect(
          rtf,
          MimeTypeHint.filename(ExampleFiles.examples_sample_rtf.path.segments.last)
        )
      odsm2 <- TikaMimetype.detect(rtf, MimeTypeHint.none)
    } yield (odsm1, odsm2)
    println(x.unsafeRunSync())
    ExitCode.Success
  }
}
