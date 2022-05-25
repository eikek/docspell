/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import java.nio.charset.StandardCharsets
import java.nio.file.Files

import scala.util.Try

import cats.data.Kleisli
import cats.effect.IO
import cats.effect.unsafe.implicits.global
import fs2.io.file.Path
import fs2.{Pipe, Stream}

import docspell.common._
import docspell.common.util.File
import docspell.convert.ConversionResult.Handler
import docspell.files.TikaMimetype

import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.encryption.InvalidPasswordException

trait FileChecks {

  implicit class FileCheckOps(p: Path) {

    def isNonEmpty: Boolean =
      Files.exists(p.toNioPath) && Files.size(p.toNioPath) > 0

    def isType(mime: MimeType): Boolean =
      TikaMimetype.detect[IO](p).map(_ == mime).unsafeRunSync()

    def isPDF: Boolean =
      isType(MimeType.pdf)

    def isPlainText: Boolean =
      isType(MimeType.text("plain"))

    def isUnencryptedPDF: Boolean =
      Try(PDDocument.load(p.toNioPath.toFile)).map(_.close()).isSuccess
  }

  implicit class ByteStreamOps(delegate: Stream[IO, Byte]) {
    def isNonEmpty: IO[Boolean] =
      delegate.head.compile.last.map(_.isDefined)

    def isType(mime: MimeType): IO[Boolean] =
      TikaMimetype.detect(delegate, MimeTypeHint.none).map(_ == mime)

    def isPDF: IO[Boolean] =
      isType(MimeType.pdf)

    def isUnencryptedPDF: IO[Boolean] =
      delegate.compile
        .to(Array)
        .map(PDDocument.load(_))
        .map(_.close())
        .map(_ => true)

    def isEncryptedPDF: IO[Boolean] =
      delegate.compile
        .to(Array)
        .map(PDDocument.load(_))
        .attempt
        .map(e =>
          e.fold(
            _.isInstanceOf[InvalidPasswordException],
            doc => {
              doc.close();
              false
            }
          )
        )
  }

  def storeFile(file: Path): Pipe[IO, Byte, Path] =
    fs2.io.file.Files[IO].writeAll(file).andThen(s => s ++ Stream.emit(file))

  def storePdfHandler(file: Path): Handler[IO, Path] =
    storePdfTxtHandler(file, file.resolveSibling("unexpected.txt")).map(_._1)

  def storePdfTxtHandler(filePdf: Path, fileTxt: Path): Handler[IO, (Path, Path)] =
    Kleisli {
      case ConversionResult.SuccessPdfTxt(pdf, txt) =>
        for {
          pout <- pdf.through(storeFile(filePdf)).compile.lastOrError
          str <- txt
          tout <- IO(Files.write(fileTxt.toNioPath, str.getBytes(StandardCharsets.UTF_8)))
        } yield (pout, File.path(tout))

      case ConversionResult.SuccessPdf(pdf) =>
        pdf.through(storeFile(filePdf)).compile.lastOrError.map(p => (p, fileTxt))

      case ConversionResult.Failure(ex) =>
        throw new Exception(s"Unexpected result (failure: ${ex.getMessage})", ex)

      case cr =>
        throw new Exception(s"Unexpected result: $cr")
    }

  def commandExists(cmd: String): Boolean =
    Runtime.getRuntime.exec(Array("which", cmd)).waitFor() == 0

}
