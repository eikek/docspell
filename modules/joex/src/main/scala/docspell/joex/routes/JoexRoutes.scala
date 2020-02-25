package docspell.joex.routes

import cats.effect._
import cats.implicits._
import docspell.common.{Duration, Ident, Timestamp}
import docspell.joex.JoexApp
import docspell.joexapi.model._
import docspell.store.records.{RJob, RJobLog}
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object JoexRoutes {

  def apply[F[_]: ConcurrentEffect: Timer](app: JoexApp[F]): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    HttpRoutes.of[F] {
      case POST -> Root / "notify" =>
        for {
          _    <- app.scheduler.notifyChange
          resp <- Ok(BasicResult(true, "Scheduler notified."))
        } yield resp

      case GET -> Root / "running" =>
        for {
          jobs <- app.scheduler.getRunning
          jj = jobs.map(mkJob)
          resp <- Ok(JobList(jj.toList))
        } yield resp

      case POST -> Root / "shutdownAndExit" =>
        for {
          _ <- ConcurrentEffect[F].start(
            Timer[F].sleep(Duration.seconds(1).toScala) *> app.initShutdown
          )
          resp <- Ok(BasicResult(true, "Shutdown initiated."))
        } yield resp

      case GET -> Root / "job" / Ident(id) =>
        for {
          optJob <- app.scheduler.getRunning.map(_.find(_.id == id))
          optLog <- optJob.traverse(j => app.findLogs(j.id))
          jAndL = for { job <- optJob; log <- optLog } yield mkJobLog(job, log)
          resp <- jAndL.map(Ok(_)).getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case POST -> Root / "job" / Ident(id) / "cancel" =>
        for {
          flag <- app.scheduler.requestCancel(id)
          resp <- Ok(BasicResult(flag, if (flag) "Cancel request submitted" else "Job not found"))
        } yield resp
    }
  }

  def mkJob(j: RJob): Job =
    Job(
      j.id,
      j.subject,
      j.submitted,
      j.priority,
      j.retries,
      j.progress,
      j.started.getOrElse(Timestamp.Epoch)
    )

  def mkJobLog(j: RJob, jl: Vector[RJobLog]): JobAndLog =
    JobAndLog(mkJob(j), jl.map(r => JobLogEvent(r.created, r.level, r.message)).toList)
}
