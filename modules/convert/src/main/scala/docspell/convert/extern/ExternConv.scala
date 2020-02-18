package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.{Pipe, Stream}
import docspell.common._

object ExternConv {

  def toPDF[F[_]: Sync: ContextShift](
      name: String,
      cmdCfg: SystemCommand.Config,
      wd: Path,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F]
  ): Pipe[F, Byte, Byte] =
    in =>
      Stream.resource(File.withTempDir[F](wd, s"docspell-$name")).flatMap { dir =>
        val out = dir.resolve("out.pdf")
        val sysCfg =
          cmdCfg.mapArgs(_.replace("{{outfile}}", out.toAbsolutePath.normalize.toString))

        SystemCommand
          .execSuccess[F](sysCfg, blocker, logger, Some(dir), in)
          .flatMap(result =>
            logResult(name, result, logger) ++ readResult[F](
              out,
              result,
              blocker,
              chunkSize,
              logger
            )
          )
      }

  def toPDFviaFile[F[_]: Sync: ContextShift](
      name: String,
      cmdCfg: SystemCommand.Config,
      wd: Path,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F]
  ): Pipe[F, Byte, Byte] =
    in =>
      Stream.resource(File.withTempDir[F](wd, s"docspell-$name")).flatMap { dir =>
        val inFile = dir.resolve("infile")
        val out    = dir.resolve("out.pdf")
        val sysCfg =
          cmdCfg.mapArgs(
            _.replace("{{outfile}}", out.toAbsolutePath.normalize.toString)
              .replace("{{infile}}", inFile.toAbsolutePath.normalize.toString)
          )

        (Stream.eval(logger.debug(s"Storing input to file ${inFile} for running $name")).drain ++
          Stream.eval(storeFile(in, inFile, blocker))).flatMap { _ =>
          SystemCommand
            .execSuccess[F](sysCfg, blocker, logger, Some(dir))
            .flatMap(result =>
              logResult(name, result, logger) ++ readResult[F](
                out,
                result,
                blocker,
                chunkSize,
                logger
              )
            )
        }
      }

  private def readResult[F[_]: Sync: ContextShift](
      out: Path,
      result: SystemCommand.Result,
      blocker: Blocker,
      chunkSize: Int,
      logger: Logger[F]
  ): Stream[F, Byte] =
    Stream.eval(File.existsNonEmpty[F](out)).flatMap {
      case true =>
        if (result.rc == 0) File.readAll(out, blocker, chunkSize)
        else
          Stream
            .eval(logger.warn(s"Command not successful (rc=${result.rc}), but file exists."))
            .drain ++
            File.readAll(out, blocker, chunkSize)

      case false =>
        Stream.raiseError[F](
          new Exception(s"Command result=${result.rc}. No output file found.")
        )
    }

  private def logResult[F[_]: Sync](
      name: String,
      result: SystemCommand.Result,
      logger: Logger[F]
  ): Stream[F, Nothing] =
    Stream.eval(logger.debug(s"$name stdout: ${result.stdout}")).drain ++
      Stream.eval(logger.debug(s"$name stderr: ${result.stderr}")).drain

  private def storeFile[F[_]: Sync: ContextShift](
    in: Stream[F, Byte],
      target: Path,
      blocker: Blocker
  ): F[Unit] =
    in.through(fs2.io.file.writeAll(target, blocker)).compile.drain
}
