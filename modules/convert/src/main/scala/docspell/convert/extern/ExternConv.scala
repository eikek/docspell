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
      useStdin: Boolean,
      blocker: Blocker,
      logger: Logger[F]
  ): Pipe[F, Byte, Byte] =
    in =>
      Stream.resource(File.withTempDir[F](wd, s"docspell-$name")).flatMap { dir =>
        val inFile = dir.resolve("infile").toAbsolutePath.normalize
        val out = dir.resolve("out.pdf").toAbsolutePath.normalize
        val sysCfg =
          cmdCfg.replace(
            Map("{{outfile}}" -> out.toString) ++
              (if (!useStdin) Map("{{infile}}" -> inFile.toString)
              else Map.empty)
          )

        val createInput: Pipe[F, Byte, Unit] =
          if (useStdin) _ => Stream.emit(())
          else storeDataToFile(name, blocker, logger, inFile)

        in.through(createInput).flatMap { _ =>
          SystemCommand
            .execSuccess[F](sysCfg, blocker, logger, Some(dir), if (useStdin) in else Stream.empty)
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

  def readResult[F[_]: Sync: ContextShift](
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

  private def storeDataToFile[F[_]: Sync: ContextShift](name: String, blocker: Blocker, logger: Logger[F], inFile: Path): Pipe[F, Byte, Unit] =
    in =>
      Stream.eval(logger.debug(s"Storing input to file ${inFile} for running $name")).drain ++
        Stream.eval(storeFile(in, inFile, blocker))

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
