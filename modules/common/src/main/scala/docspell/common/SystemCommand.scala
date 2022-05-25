/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.io.InputStream
import java.lang.ProcessBuilder.Redirect
import java.util.concurrent.TimeUnit

import scala.jdk.CollectionConverters._

import cats.effect._
import cats.implicits._
import fs2.io.file.Path
import fs2.{Stream, io, text}

import docspell.common.{exec => newExec}
import docspell.logging.Logger

// better use `SysCmd` and `SysExec`
object SystemCommand {

  final case class Config(
      program: String,
      args: Seq[String],
      timeout: Duration,
      env: Map[String, String] = Map.empty
  ) {

    def toSysCmd = newExec
      .SysCmd(program, newExec.Args(args))
      .withTimeout(timeout)
      .addEnv(newExec.Env(env))

    def mapArgs(f: String => String): Config =
      Config(program, args.map(f), timeout)

    def replace(repl: Map[String, String]): Config =
      mapArgs(s =>
        repl.foldLeft(s) { case (res, (k, v)) =>
          res.replace(k, v)
        }
      )

    def withEnv(key: String, value: String): Config =
      copy(env = env.updated(key, value))

    def addEnv(moreEnv: Map[String, String]): Config =
      copy(env = env ++ moreEnv)

    def appendArgs(extraArgs: Args): Config =
      copy(args = args ++ extraArgs.args)

    def appendArgs(extraArgs: Seq[String]): Config =
      copy(args = args ++ extraArgs)

    def toCmd: List[String] =
      program :: args.toList

    lazy val cmdString: String =
      toCmd.mkString(" ")
  }

  final case class Args(args: Vector[String]) extends Iterable[String] {
    override def iterator = args.iterator

    def prepend(a: String): Args = Args(a +: args)

    def prependWhen(flag: Boolean)(a: String): Args =
      prependOption(Option.when(flag)(a))

    def prependOption(value: Option[String]): Args =
      value.map(prepend).getOrElse(this)

    def append(a: String, as: String*): Args =
      Args(args ++ (a +: as.toVector))

    def appendOption(value: Option[String]): Args =
      value.map(append(_)).getOrElse(this)

    def appendOptionVal(first: String, second: Option[String]): Args =
      second.map(b => append(first, b)).getOrElse(this)

    def appendWhen(flag: Boolean)(a: String, as: String*): Args =
      if (flag) append(a, as: _*) else this

    def appendWhenNot(flag: Boolean)(a: String, as: String*): Args =
      if (!flag) append(a, as: _*) else this

    def append(p: Path): Args =
      append(p.toString)

    def append(as: Iterable[String]): Args =
      Args(args ++ as.toVector)
  }
  object Args {
    val empty: Args = Args()

    def apply(as: String*): Args =
      Args(as.toVector)
  }

  final case class Result(rc: Int, stdout: String, stderr: String)

  def exec[F[_]: Sync](
      cmd: Config,
      logger: Logger[F],
      wd: Option[Path] = None,
      stdin: Stream[F, Byte] = Stream.empty
  ): Stream[F, Result] =
    startProcess(cmd, wd, logger, stdin) { proc =>
      Stream.eval {
        for {
          _ <- writeToProcess(stdin, proc)
          term <- Sync[F].blocking(proc.waitFor(cmd.timeout.seconds, TimeUnit.SECONDS))
          _ <-
            if (term)
              logger.debug(s"Command `${cmd.cmdString}` finished: ${proc.exitValue}")
            else
              logger.warn(
                s"Command `${cmd.cmdString}` did not finish in ${cmd.timeout.formatExact}!"
              )
          _ <- if (!term) timeoutError(proc, cmd) else Sync[F].pure(())
          out <-
            if (term) inputStreamToString(proc.getInputStream)
            else Sync[F].pure("")
          err <-
            if (term) inputStreamToString(proc.getErrorStream)
            else Sync[F].pure("")
        } yield Result(proc.exitValue, out, err)
      }
    }

  def execSuccess[F[_]: Sync](
      cmd: Config,
      logger: Logger[F],
      wd: Option[Path] = None,
      stdin: Stream[F, Byte] = Stream.empty
  ): Stream[F, Result] =
    exec(cmd, logger, wd, stdin).flatMap { r =>
      if (r.rc != 0)
        Stream.raiseError[F](
          new Exception(
            s"Command `${cmd.cmdString}` returned non-zero exit code ${r.rc}. Stderr: ${r.stderr}"
          )
        )
      else Stream.emit(r)
    }

  private def startProcess[F[_]: Sync, A](
      cmd: Config,
      wd: Option[Path],
      logger: Logger[F],
      stdin: Stream[F, Byte]
  )(
      f: Process => Stream[F, A]
  ): Stream[F, A] = {
    val log = logger.debug(s"Running external command: ${cmd.cmdString}")
    val hasStdin = stdin.take(1).compile.last.map(_.isDefined)
    val proc = log *> hasStdin.flatMap(flag =>
      Sync[F].blocking {
        val pb = new ProcessBuilder(cmd.toCmd.asJava)
          .redirectInput(if (flag) Redirect.PIPE else Redirect.INHERIT)
          .redirectError(Redirect.PIPE)
          .redirectOutput(Redirect.PIPE)

        val pbEnv = pb.environment()
        cmd.env.foreach { case (key, value) =>
          pbEnv.put(key, value)
        }
        wd.map(_.toNioPath.toFile).foreach(pb.directory)
        pb.start()
      }
    )
    Stream
      .bracket(proc)(p =>
        logger.debug(s"Closing process: `${cmd.cmdString}`").map(_ => p.destroy())
      )
      .flatMap(f)
  }

  private def inputStreamToString[F[_]: Sync](in: InputStream): F[String] =
    io.readInputStream(Sync[F].pure(in), 16 * 1024, closeAfterUse = false)
      .through(text.utf8.decode)
      .chunks
      .map(_.toVector.mkString)
      .fold1(_ + _)
      .compile
      .last
      .map(_.getOrElse(""))

  private def writeToProcess[F[_]: Sync](
      data: Stream[F, Byte],
      proc: Process
  ): F[Unit] =
    data
      .through(io.writeOutputStream(Sync[F].blocking(proc.getOutputStream)))
      .compile
      .drain

  private def timeoutError[F[_]: Sync](proc: Process, cmd: Config): F[Unit] =
    Sync[F].blocking(proc.destroyForcibly()).attempt *> {
      Sync[F].raiseError(
        new Exception(
          s"Command `${cmd.cmdString}` timed out (${cmd.timeout.formatExact})"
        )
      )
    }
}
