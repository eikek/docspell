package docspell.convert.extern

import java.nio.file.Path

import cats.implicits._
import cats.effect._
import fs2.{Pipe, Stream}
import docspell.common._
import docspell.convert.ConversionResult
import docspell.convert.ConversionResult.{Handler, successPdf, successPdfTxt}

private[extern] object ExternConv {

  def toPDF[F[_]: Sync: ContextShift, A](
      name: String,
      cmdCfg: SystemCommand.Config,
      wd: Path,
      useStdin: Boolean,
      blocker: Blocker,
      logger: Logger[F],
      reader: (Path, SystemCommand.Result) => F[ConversionResult[F]]
  )(in: Stream[F, Byte], handler: Handler[F, A]): F[A] =
    Stream
      .resource(File.withTempDir[F](wd, s"docspell-$name"))
      .flatMap { dir =>
        val inFile = dir.resolve("infile").toAbsolutePath.normalize
        val out    = dir.resolve("out.pdf").toAbsolutePath.normalize
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
          else storeDataToFile(name, blocker, logger, inFile)

        in.through(createInput).flatMap { _ =>
          SystemCommand
            .execSuccess[F](
              sysCfg,
              blocker,
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

  def readResult[F[_]: Sync: ContextShift](
      blocker: Blocker,
      chunkSize: Int,
      logger: Logger[F]
  )(out: Path, result: SystemCommand.Result): F[ConversionResult[F]] =
    File.existsNonEmpty[F](out).flatMap {
      case true =>
        if (result.rc == 0) successPdf(File.readAll(out, blocker, chunkSize)).pure[F]
        else
          logger.warn(s"Command not successful (rc=${result.rc}), but file exists.") *>
            successPdf(File.readAll(out, blocker, chunkSize)).pure[F]

      case false =>
        ConversionResult
          .failure[F](
            new Exception(s"Command result=${result.rc}. No output file found.")
          )
          .pure[F]
    }

  def readResultTesseract[F[_]: Sync: ContextShift](
      outPrefix: String,
      blocker: Blocker,
      chunkSize: Int,
      logger: Logger[F]
  )(out: Path, result: SystemCommand.Result): F[ConversionResult[F]] = {
    val outPdf = out.resolveSibling(s"$outPrefix.pdf")
    File.existsNonEmpty[F](outPdf).flatMap {
      case true =>
        val outTxt = out.resolveSibling(s"$outPrefix.txt")
        File.exists(outTxt).flatMap { txtExists =>
          val pdfData = File.readAll(out, blocker, chunkSize)
          if (result.rc == 0)
            if (txtExists) successPdfTxt(pdfData, File.readText(outTxt, blocker)).pure[F]
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

  private def storeDataToFile[F[_]: Sync: ContextShift](
      name: String,
      blocker: Blocker,
      logger: Logger[F],
      inFile: Path
  ): Pipe[F, Byte, Unit] =
    in =>
      Stream
        .eval(logger.debug(s"Storing input to file ${inFile} for running $name"))
        .drain ++
        Stream.eval(storeFile(in, inFile, blocker))

  private def logResult[F[_]: Sync](
      name: String,
      result: SystemCommand.Result,
      logger: Logger[F]
  ): F[Unit] =
    logger.debug(s"$name stdout: ${result.stdout}") *>
      logger.debug(s"$name stderr: ${result.stderr}")

  private def storeFile[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      target: Path,
      blocker: Blocker
  ): F[Unit] =
    in.through(fs2.io.file.writeAll(target, blocker)).compile.drain
}
