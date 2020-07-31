package docspell.build

import sbt._
import scala.sys.process._
import java.util.concurrent.atomic.AtomicReference

/** Helper for running external commands. */
object Cmd {

  case class Result(rc: Int, out: String, err: String) {

    def throwIfNot(success: Int): Result =
      if (rc != success) sys.error(s"Unsuccessful return: $rc")
      else this
  }

  def run(cmd: Seq[String], wd: File, logger: Logger): Unit = {
    val res = Cmd.exec(cmd, Some(wd))
    logger.info(res.out)
    logger.error(res.err)
    res.throwIfNot(0)
  }

  def exec(cmd: Seq[String], wd: Option[File]): Result = {
    val capt = new Capture
    val rc   = Process(cmd, wd).!(capt.logger)
    Result(rc, capt.out.get.mkString("\n"), capt.err.get.mkString("\n"))
  }

  final private class Capture {
    val err = new AtomicReference[List[String]](Nil)
    val out = new AtomicReference[List[String]](Nil)

    val logger = ProcessLogger(
      line => out.getAndAccumulate(List(line), _ ++ _),
      line => err.getAndAccumulate(List(line), _ ++ _)
    )

  }
}
