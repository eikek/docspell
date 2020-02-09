package docspell.text.ocr

import java.io.InputStream
import java.nio.file.Path
import java.util.concurrent.TimeUnit
import cats.implicits._
import cats.effect.{Blocker, ContextShift, Sync}
import fs2.{Stream, io, text}
import org.log4s.getLogger
import scala.jdk.CollectionConverters._
import docspell.common.syntax.all._

object SystemCommand {

  private[this] val logger = getLogger

  final case class Result(rc: Int, stdout: String, stderr: String)

  def exec[F[_]: Sync: ContextShift](
      cmd: Config.Command,
      blocker: Blocker,
      wd: Option[Path] = None,
      stdin: Stream[F, Byte] = Stream.empty
  ): Stream[F, Result] =
    startProcess(cmd, wd) { proc =>
      Stream.eval {
        for {
          _    <- writeToProcess(stdin, proc, blocker)
          term <- Sync[F].delay(proc.waitFor(cmd.timeout.seconds, TimeUnit.SECONDS))
          _ <- if (term) logger.fdebug(s"Command `${cmd.cmdString}` finished: ${proc.exitValue}")
              else
                logger.fwarn(
                  s"Command `${cmd.cmdString}` did not finish in ${cmd.timeout.formatExact}!"
                )
          _   <- if (!term) timeoutError(proc, cmd) else Sync[F].pure(())
          out <- if (term) inputStreamToString(proc.getInputStream, blocker) else Sync[F].pure("")
          err <- if (term) inputStreamToString(proc.getErrorStream, blocker) else Sync[F].pure("")
        } yield Result(proc.exitValue, out, err)
      }
    }

  def execSuccess[F[_]: Sync: ContextShift](
      cmd: Config.Command,
      blocker: Blocker,
      wd: Option[Path] = None,
      stdin: Stream[F, Byte] = Stream.empty
  ): Stream[F, Result] =
    exec(cmd, blocker, wd, stdin).flatMap { r =>
      if (r.rc != 0)
        Stream.raiseError[F](
          new Exception(
            s"Command `${cmd.cmdString}` returned non-zero exit code ${r.rc}. Stderr: ${r.stderr}"
          )
        )
      else Stream.emit(r)
    }

  private def startProcess[F[_]: Sync, A](cmd: Config.Command, wd: Option[Path])(
      f: Process => Stream[F, A]
  ): Stream[F, A] = {
    val log = logger.fdebug(s"Running external command: ${cmd.cmdString}")
    val proc = log *> Sync[F].delay {
      val pb = new ProcessBuilder(cmd.toCmd.asJava)
      wd.map(_.toFile).foreach(pb.directory)
      pb.start()
    }
    Stream
      .bracket(proc)(p =>
        logger.fdebug(s"Closing process: `${cmd.cmdString}`").map { _ =>
          p.destroy()
        }
      )
      .flatMap(f)
  }

  private def inputStreamToString[F[_]: Sync: ContextShift](
      in: InputStream,
      blocker: Blocker
  ): F[String] =
    io.readInputStream(Sync[F].pure(in), 16 * 1024, blocker, closeAfterUse = false)
      .through(text.utf8Decode)
      .chunks
      .map(_.toVector.mkString)
      .fold1(_ + _)
      .compile
      .last
      .map(_.getOrElse(""))

  private def writeToProcess[F[_]: Sync: ContextShift](
      data: Stream[F, Byte],
      proc: Process,
      blocker: Blocker
  ): F[Unit] =
    data.through(io.writeOutputStream(Sync[F].delay(proc.getOutputStream), blocker)).compile.drain

  private def timeoutError[F[_]: Sync](proc: Process, cmd: Config.Command): F[Unit] =
    Sync[F].delay(proc.destroyForcibly()).attempt *> {
      Sync[F].raiseError(
        new Exception(s"Command `${cmd.cmdString}` timed out (${cmd.timeout.formatExact})")
      )
    }
}
