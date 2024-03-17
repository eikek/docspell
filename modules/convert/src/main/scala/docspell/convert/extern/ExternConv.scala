/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import cats.effect._
import cats.implicits._
import fs2.io.file.{Files, Path}
import fs2.{Pipe, Stream}

import docspell.common.exec.ExternalCommand
import docspell.common.exec.SysExec
import docspell.common.util.File
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.{Handler, successPdf, successPdfTxt}
import docspell.logging.Logger

private[extern] object ExternConv {

  def toPDF[F[_]: Async: Files, A](
      name: String,
      cmdCfg: ExternalCommand.WithVars,
      wd: Path,
      useStdin: Boolean,
      logger: Logger[F],
      reader: (Path, Int) => F[ConversionResult[F]]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] =
    Stream
      .resource(File.withTempDir[F](wd, s"docspell-$name"))
      .flatMap { dir =>
        val inFile = dir.resolve("infile").absolute.normalize
        val out = dir.resolve("out.pdf").absolute.normalize
        val sysCfg =
          cmdCfg
            .withVar("outfile", out.toString)
            .withVarOption("infile", Option.when(!useStdin)(inFile.toString))
            .resolved

        val createInput: Pipe[F, Byte, Unit] =
          if (useStdin) _ => Stream.emit(())
          else storeDataToFile(name, logger, inFile)

        in.through(createInput).evalMap { _ =>
          SysExec(sysCfg, logger, Some(dir), Option.when(useStdin)(in))
            .flatMap(_.logOutputs(logger, name))
            .use { proc =>
              proc.waitFor().flatMap(rc => reader(out, rc).flatMap(handler.run))
            }
        }
      }
      .compile
      .lastOrError
      .attempt
      .flatMap {
        case Right(v) =>
          v.pure[F]
        case Left(ex) =>
          handler.run(ConversionResult.failure(ex))
      }

  def readResult[F[_]: Async: Files](
      chunkSize: Int,
      logger: Logger[F]
  )(out: Path, result: Int): F[ConversionResult[F]] =
    File.existsNonEmpty[F](out).flatMap {
      case true if result == 0 =>
        val outTxt = out.resolveSibling(out.fileName.toString + ".txt")
        File.existsNonEmpty[F](outTxt).flatMap {
          case true =>
            successPdfTxt(
              File.readAll(out, chunkSize),
              File.readText(outTxt)
            ).pure[F]
          case false =>
            successPdf(File.readAll(out, chunkSize)).pure[F]
        }
      case true =>
        logger.warn(s"Command not successful (rc=${result}), but file exists.") *>
          successPdf(File.readAll(out, chunkSize)).pure[F]

      case false =>
        ConversionResult
          .failure[F](
            new Exception(s"Command result=${result}. No output file found.")
          )
          .pure[F]
    }

  def readResultTesseract[F[_]: Async: Files](
      outPrefix: String,
      chunkSize: Int,
      logger: Logger[F]
  )(out: Path, result: Int): F[ConversionResult[F]] = {
    val outPdf = out.resolveSibling(s"$outPrefix.pdf")
    File.existsNonEmpty[F](outPdf).flatMap {
      case true =>
        val outTxt = out.resolveSibling(s"$outPrefix.txt")
        File.exists(outTxt).flatMap { txtExists =>
          val pdfData = File.readAll(out, chunkSize)
          if (result == 0)
            if (txtExists) successPdfTxt(pdfData, File.readText(outTxt)).pure[F]
            else successPdf(pdfData).pure[F]
          else
            logger.warn(s"Command not successful (rc=${result}), but file exists.") *>
              successPdf(pdfData).pure[F]
        }

      case false =>
        ConversionResult
          .failure[F](
            new Exception(s"Command result=${result}. No output file found.")
          )
          .pure[F]
    }
  }

  private def storeDataToFile[F[_]: Async: Files](
      name: String,
      logger: Logger[F],
      inFile: Path
  ): Pipe[F, Byte, Unit] =
    in =>
      Stream
        .eval(logger.debug(s"Storing input to file $inFile for running $name"))
        .drain ++
        Stream.eval(storeFile(in, inFile))

  private def storeFile[F[_]: Async: Files](
      in: Stream[F, Byte],
      target: Path
  ): F[Unit] =
    in.through(Files[F].writeAll(target)).compile.drain
}
