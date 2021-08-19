/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.convert.extern

import cats.effect._
import cats.implicits._
import fs2.io.file.{Files, Path}
import fs2.{Pipe, Stream}

import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.{Handler, successPdf, successPdfTxt}

private[extern] object ExternConv {

  def toPDF[F[_]: Async, A](
      name: String,
      cmdCfg: SystemCommand.Config,
      wd: Path,
      useStdin: Boolean,
      logger: Logger[F],
      reader: (Path, SystemCommand.Result) => F[ConversionResult[F]]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] =
    Stream
      .resource(File.withTempDir[F](wd, s"docspell-$name"))
      .flatMap { dir =>
        val inFile = dir.resolve("infile").absolute.normalize
        val out    = dir.resolve("out.pdf").absolute.normalize
        val sysCfg =
          cmdCfg.replace(
            Map(
              "{{outfile}}" -> out.toString
            ) ++
              (if (!useStdin) Map("{{infile}}" -> inFile.toString)
               else Map.empty)
          )

        val createInput: Pipe[F, Byte, Unit] =
          if (useStdin) _ => Stream.emit(())
          else storeDataToFile(name, logger, inFile)

        in.through(createInput).flatMap { _ =>
          SystemCommand
            .exec[F](
              sysCfg,
              logger,
              Some(dir),
              if (useStdin) in
              else Stream.empty
            )
            .evalMap(result =>
              logResult(name, result, logger)
                .flatMap(_ => reader(out, result))
                .flatMap(handler.run)
            )
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

  def readResult[F[_]: Async](
      chunkSize: Int,
      logger: Logger[F]
  )(out: Path, result: SystemCommand.Result): F[ConversionResult[F]] =
    File.existsNonEmpty[F](out).flatMap {
      case true if result.rc == 0 =>
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
        logger.warn(s"Command not successful (rc=${result.rc}), but file exists.") *>
          successPdf(File.readAll(out, chunkSize)).pure[F]

      case false =>
        ConversionResult
          .failure[F](
            new Exception(s"Command result=${result.rc}. No output file found.")
          )
          .pure[F]
    }

  def readResultTesseract[F[_]: Async](
      outPrefix: String,
      chunkSize: Int,
      logger: Logger[F]
  )(out: Path, result: SystemCommand.Result): F[ConversionResult[F]] = {
    val outPdf = out.resolveSibling(s"$outPrefix.pdf")
    File.existsNonEmpty[F](outPdf).flatMap {
      case true =>
        val outTxt = out.resolveSibling(s"$outPrefix.txt")
        File.exists(outTxt).flatMap { txtExists =>
          val pdfData = File.readAll(out, chunkSize)
          if (result.rc == 0)
            if (txtExists) successPdfTxt(pdfData, File.readText(outTxt)).pure[F]
            else successPdf(pdfData).pure[F]
          else
            logger.warn(s"Command not successful (rc=${result.rc}), but file exists.") *>
              successPdf(pdfData).pure[F]
        }

      case false =>
        ConversionResult
          .failure[F](
            new Exception(s"Command result=${result.rc}. No output file found.")
          )
          .pure[F]
    }
  }

  private def storeDataToFile[F[_]: Async](
      name: String,
      logger: Logger[F],
      inFile: Path
  ): Pipe[F, Byte, Unit] =
    in =>
      Stream
        .eval(logger.debug(s"Storing input to file $inFile for running $name"))
        .drain ++
        Stream.eval(storeFile(in, inFile))

  private def logResult[F[_]: Sync](
      name: String,
      result: SystemCommand.Result,
      logger: Logger[F]
  ): F[Unit] =
    logger.debug(s"$name stdout: ${result.stdout}") *>
      logger.debug(s"$name stderr: ${result.stderr}")

  private def storeFile[F[_]: Async](
      in: Stream[F, Byte],
      target: Path
  ): F[Unit] =
    in.through(Files[F].writeAll(target)).compile.drain
}
