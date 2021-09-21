/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import java.nio.charset.StandardCharsets
import java.nio.file.Files

import cats.data.Kleisli
import cats.effect.IO
import cats.effect.unsafe.implicits.global
import fs2.io.file.Path
import fs2.{Pipe, Stream}

import docspell.common._
import docspell.convert.ConversionResult.Handler
import docspell.files.TikaMimetype

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
  }

  def storeFile(file: Path): Pipe[IO, Byte, Path] =
    in =>
      Stream
        .eval(
          in.compile.to(Array).flatMap(bytes => IO(Files.write(file.toNioPath, bytes)))
        )
        .map(p => File.path(p))

  def storePdfHandler(file: Path): Handler[IO, Path] =
    storePdfTxtHandler(file, file.resolveSibling("unexpected.txt")).map(_._1)

  def storePdfTxtHandler(filePdf: Path, fileTxt: Path): Handler[IO, (Path, Path)] =
    Kleisli {
      case ConversionResult.SuccessPdfTxt(pdf, txt) =>
        for {
          pout <- pdf.through(storeFile(filePdf)).compile.lastOrError
          str  <- txt
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
