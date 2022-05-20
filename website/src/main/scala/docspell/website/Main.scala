package docspell.website

import cats.effect.{ExitCode, IO, IOApp}
import fs2.io.file.{Files, Path}
import fs2.Stream
import io.circe.Encoder
import io.circe.syntax._

object Main extends IOApp {
  override def run(args: List[String]) =
    args match {
      case "addon-output" :: file :: Nil =>
        if (file.isEmpty) ok(stdout(AddonOutputExample.exampleJson))
        else ok(AddonOutputExample.example.writeFile(file))

      case "addon-output-tags" :: file :: Nil =>
        if (file.isEmpty) ok(stdout(AddonOutputMiniExample.exampleJson))
        else ok(AddonOutputMiniExample.example.writeFile(file))

      case "item-data" :: file :: Nil =>
        if (file.isEmpty) ok(stdout(ItemDataExample.exampleJson))
        else ok(ItemDataExample.example.writeFile(file))

      case "item-args" :: file :: Nil =>
        if (file.isEmpty) ok(stdout(ItemArgsExample.exampleJson))
        else ok(ItemArgsExample.example.writeFile(file))

      case "file-meta" :: file :: Nil =>
        if (file.isEmpty) ok(stdout(FileMetaExample.exampleJson))
        else ok(FileMetaExample.example.writeFile(file))

      case v :: Nil =>
        err(stderr(s"Unknown example: $v"))

      case _ =>
        err(stderr("Specify what example to print"))
    }

  def stdout(str: String, args: Any*): Unit =
    Console.out.println(str.format(args: _*))

  def stderr(str: String, args: Any*): Unit =
    Console.err.println(str.format(args: _*))

  def ok(f: IO[Unit]): IO[ExitCode] =
    f.as(ExitCode.Success)

  def ok(p: => Unit): IO[ExitCode] =
    ok(IO(p))

  def err(p: => Unit): IO[ExitCode] =
    IO(p).as(ExitCode.Error)

  implicit class WriteOps[A: Encoder](self: A) {
    def writeFile(file: String): IO[Unit] =
      Stream
        .emit(self.asJson.spaces2)
        .covary[IO]
        .through(fs2.text.utf8.encode)
        .through(Files[IO].writeAll(Path(file)))
        .compile
        .drain
  }
}
