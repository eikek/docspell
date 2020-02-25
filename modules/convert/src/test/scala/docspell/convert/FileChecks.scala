package docspell.convert

import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path}

import cats.data.Kleisli
import cats.effect.IO
import fs2.{Pipe, Stream}
import docspell.common.MimeType
import docspell.convert.ConversionResult.Handler
import docspell.files.TikaMimetype

trait FileChecks {

  implicit class FileCheckOps(p: Path) {

    def isNonEmpty: Boolean =
      Files.exists(p) && Files.size(p) > 0

    def isType(mime: MimeType): Boolean =
      TikaMimetype.detect[IO](p).map(_ == mime).unsafeRunSync

    def isPDF: Boolean =
      isType(MimeType.pdf)

    def isPlainText: Boolean =
      isType(MimeType.text("plain"))
  }

  def storeFile(file: Path): Pipe[IO, Byte, Path] =
    in => Stream.eval(in.compile.to(Array).flatMap(bytes => IO(Files.write(file, bytes))))

  def storePdfHandler(file: Path): Handler[IO, Path] =
    storePdfTxtHandler(file, file.resolveSibling("unexpected.txt")).map(_._1)

  def storePdfTxtHandler(filePdf: Path, fileTxt: Path): Handler[IO, (Path, Path)] =
    Kleisli({
      case ConversionResult.SuccessPdfTxt(pdf, txt) =>
        for {
          pout <- pdf.through(storeFile(filePdf)).compile.lastOrError
          str  <- txt
          tout <- IO(Files.write(fileTxt, str.getBytes(StandardCharsets.UTF_8)))
        } yield (pout, tout)

      case ConversionResult.SuccessPdf(pdf) =>
        pdf.through(storeFile(filePdf)).compile.lastOrError.map(p => (p, fileTxt))

      case ConversionResult.Failure(ex) =>
        throw new Exception(s"Unexpected result (failure: ${ex.getMessage})", ex)

      case cr =>
        throw new Exception(s"Unexpected result: $cr")
    })

  def commandExists(cmd: String): Boolean =
    Runtime.getRuntime.exec(Array("which", cmd)).waitFor() == 0

}
