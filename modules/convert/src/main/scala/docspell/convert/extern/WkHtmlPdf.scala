package docspell.convert.extern

import java.nio.file.Path

import cats.effect._
import fs2.{Pipe, Stream}
import docspell.common._

object WkHtmlPdf {

  def toPDF[F[_]: Sync: ContextShift](
      cfg: WkHtmlPdfConfig,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F]
  ): Pipe[F, Byte, Byte] =
    in =>
      Stream.resource(File.withTempDir[F](cfg.workingDir, "docspell-wkhtmltopdf")).flatMap { dir =>
        val out = dir.resolve("out.pdf")
        val sysCfg =
          cfg.cmd.mapArgs(_.replace("{{outfile}}", out.toAbsolutePath.normalize.toString))

        Stream.eval(logger.info(s"Running ${sysCfg.program}")).drain ++
          SystemCommand
            .execSuccess[F](sysCfg, blocker, Some(dir), in)
            .flatMap(result => readResult[F](out, result, blocker, chunkSize, logger))
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
        Stream.raiseError(
          new Exception(s"Command result=${result.rc}. No output file found. ${result.stderr}")
        )
    }
}
