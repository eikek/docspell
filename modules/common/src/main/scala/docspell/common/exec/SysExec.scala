/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

import java.lang.ProcessBuilder.Redirect
import java.util.concurrent.TimeUnit

import scala.concurrent.TimeoutException
import scala.jdk.CollectionConverters._

import cats.effect._
import cats.syntax.all._
import fs2.io.file.Path
import fs2.{Pipe, Stream}

import docspell.common.Duration
import docspell.logging.Logger

trait SysExec[F[_]] {

  def stdout: Stream[F, Byte]

  def stdoutLines: Stream[F, String] =
    stdout
      .through(fs2.text.utf8.decode)
      .through(fs2.text.lines)

  def stderr: Stream[F, Byte]

  def stderrLines: Stream[F, String] =
    stderr
      .through(fs2.text.utf8.decode)
      .through(fs2.text.lines)

  def waitFor(timeout: Option[Duration] = None): F[Int]

  /** Uses `waitFor` and throws when return code is non-zero. Logs stderr and stdout while
    * waiting.
    */
  def runToSuccess(logger: Logger[F], timeout: Option[Duration] = None)(implicit
      F: Async[F]
  ): F[Int]

  /** Uses `waitFor` and throws when return code is non-zero. Logs stderr while waiting
    * and collects stdout once finished successfully.
    */
  def runToSuccessStdout(logger: Logger[F], timeout: Option[Duration] = None)(implicit
      F: Async[F]
  ): F[String]

  /** Sends a signal to the process to terminate it immediately */
  def cancel: F[Unit]

  /** Consume lines of output of the process in background. */
  def consumeOutputs(out: Pipe[F, String, Unit], err: Pipe[F, String, Unit])(implicit
      F: Async[F]
  ): Resource[F, SysExec[F]]

  /** Consumes stderr lines (left) and stdout lines (right) in a background thread. */
  def consumeOutputs(
      m: Either[String, String] => F[Unit]
  )(implicit F: Async[F]): Resource[F, SysExec[F]] = {
    val pe: Pipe[F, String, Unit] = _.map(_.asLeft).evalMap(m)
    val po: Pipe[F, String, Unit] = _.map(_.asRight).evalMap(m)
    consumeOutputs(po, pe)
  }

  def logOutputs(logger: Logger[F], name: String)(implicit F: Async[F]) =
    consumeOutputs {
      case Right(line) => logger.debug(s"[$name (out)]: $line")
      case Left(line)  => logger.debug(s"[$name (err)]: $line")
    }
}

object SysExec {
  private val readChunkSz = 8 * 1024

  def apply[F[_]: Sync](
      cmd: SysCmd,
      logger: Logger[F],
      workdir: Option[Path] = None,
      stdin: Option[Stream[F, Byte]] = None
  ): Resource[F, SysExec[F]] =
    for {
      proc <- startProcess(logger, cmd, workdir, stdin)
      fibers <- Resource.eval(Ref.of[F, List[F[Unit]]](Nil))
    } yield new SysExec[F] {
      private lazy val basicName: String =
        cmd.program.lastIndexOf(java.io.File.separatorChar.toInt) match {
          case n if n > 0 => cmd.program.drop(n + 1)
          case _          => cmd.program.takeRight(16)
        }

      def stdout: Stream[F, Byte] =
        fs2.io.readInputStream(
          Sync[F].blocking(proc.getInputStream),
          readChunkSz,
          closeAfterUse = false
        )

      def stderr: Stream[F, Byte] =
        fs2.io.readInputStream(
          Sync[F].blocking(proc.getErrorStream),
          readChunkSz,
          closeAfterUse = false
        )

      def cancel = Sync[F].blocking(proc.destroy())

      def waitFor(timeout: Option[Duration]): F[Int] = {
        val to = timeout.getOrElse(cmd.timeout)
        logger.trace("Waiting for command to terminate…") *>
          Sync[F]
            .blocking(proc.waitFor(to.millis, TimeUnit.MILLISECONDS))
            .flatTap(_ => fibers.get.flatMap(_.traverse_(identity)))
            .flatMap(terminated =>
              if (terminated) proc.exitValue().pure[F]
              else
                Sync[F]
                  .raiseError(
                    new TimeoutException(s"Timed out after: ${to.formatExact}")
                  )
            )
      }

      def runToSuccess(logger: Logger[F], timeout: Option[Duration])(implicit
          F: Async[F]
      ): F[Int] =
        logOutputs(logger, basicName).use(_.waitFor(timeout).flatMap {
          case rc if rc == 0 => Sync[F].pure(0)
          case rc =>
            Sync[F].raiseError(
              new Exception(s"Command `${cmd.program}` returned non-zero exit code ${rc}")
            )
        })

      def runToSuccessStdout(logger: Logger[F], timeout: Option[Duration])(implicit
          F: Async[F]
      ): F[String] =
        F.background(
          stderrLines
            .through(line => Stream.eval(logger.debug(s"[$basicName (err)]: $line")))
            .compile
            .drain
        ).use { f1 =>
          waitFor(timeout)
            .flatMap {
              case rc if rc == 0 => stdout.through(fs2.text.utf8.decode).compile.string
              case rc =>
                Sync[F].raiseError[String](
                  new Exception(
                    s"Command `${cmd.program}` returned non-zero exit code ${rc}"
                  )
                )
            }
            .flatTap(_ => f1)
        }

      def consumeOutputs(out: Pipe[F, String, Unit], err: Pipe[F, String, Unit])(implicit
          F: Async[F]
      ): Resource[F, SysExec[F]] =
        for {
          f1 <- F.background(stdoutLines.through(out).compile.drain)
          f2 <- F.background(stderrLines.through(err).compile.drain)
          _ <- Resource.eval(fibers.update(list => f1.void :: f2.void :: list))
        } yield this
    }

  private def startProcess[F[_]: Sync, A](
      logger: Logger[F],
      cmd: SysCmd,
      workdir: Option[Path],
      stdin: Option[Stream[F, Byte]]
  ): Resource[F, Process] = {
    val log = logger.debug(s"Running external command: ${cmd.cmdString}")

    val proc = log *>
      Sync[F].blocking {
        val pb = new ProcessBuilder(cmd.toCmd.asJava)
          .redirectInput(if (stdin.isDefined) Redirect.PIPE else Redirect.INHERIT)
          .redirectError(Redirect.PIPE)
          .redirectOutput(Redirect.PIPE)

        val pbEnv = pb.environment()
        cmd.env.foreach { (name, v) =>
          pbEnv.put(name, v)
          ()
        }
        workdir.map(_.toNioPath.toFile).foreach(pb.directory)
        pb.start()
      }

    Resource
      .make(proc)(p =>
        logger.debug(s"Closing process: `${cmd.cmdString}`").map(_ => p.destroy())
      )
      .evalMap(p =>
        stdin match {
          case Some(in) =>
            writeToProcess(in, p).compile.drain.as(p)
          case None =>
            p.pure[F]
        }
      )
  }

  private def writeToProcess[F[_]: Sync](
      data: Stream[F, Byte],
      proc: Process
  ): Stream[F, Nothing] =
    data.through(fs2.io.writeOutputStream(Sync[F].blocking(proc.getOutputStream)))
}
