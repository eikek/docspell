/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.routes

import cats.effect._
import cats.implicits._

import docspell.common.{Duration, Ident, Timestamp}
import docspell.joex.{Config, JoexApp}
import docspell.joexapi.model._
import docspell.store.records.RJobLog

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object JoexRoutes {

  def apply[F[_]: Async](cfg: Config, app: JoexApp[F]): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    HttpRoutes.of[F] {
      case POST -> Root / "notify" =>
        for {
          _ <- app.scheduler.notifyChange
          _ <- app.periodicScheduler.notifyChange
          resp <- Ok(BasicResult(success = true, "Schedulers notified."))
        } yield resp

      case GET -> Root / "running" =>
        for {
          jobs <- app.scheduler.getRunning
          jj = jobs.map(mkJob)
          resp <- Ok(JobList(jj.toList))
        } yield resp

      case POST -> Root / "shutdownAndExit" =>
        for {
          _ <- Async[F].start(
            Temporal[F].sleep(Duration.seconds(1).toScala) *> app.initShutdown
          )
          resp <- Ok(BasicResult(success = true, "Shutdown initiated."))
        } yield resp

      case GET -> Root / "job" / Ident(id) =>
        for {
          optJob <- app.scheduler.getRunning.map(_.find(_.id == id))
          optLog <- optJob.traverse(j => app.findLogs(j.id))
          jAndL = for {
            job <- optJob
            log <- optLog
          } yield mkJobLog(job, log)
          resp <- jAndL
            .map(Ok(_))
            .getOrElse(NotFound(BasicResult(success = false, "Not found")))
        } yield resp

      case POST -> Root / "job" / Ident(id) / "cancel" =>
        for {
          flag <- app.scheduler.requestCancel(id)
          resp <- Ok(
            BasicResult(flag, if (flag) "Cancel request submitted" else "Job not found")
          )
        } yield resp

      case GET -> Root / "addon" / "config" =>
        val data =
          AddonSupport(cfg.appId, cfg.addons.executorConfig.runner)
        Ok(data)
    }
  }

  // TODO !!

  def mkJob(j: docspell.scheduler.Job[String]): Job =
    Job(
      j.id,
      j.subject,
      Timestamp.Epoch,
      j.priority,
      -1,
      -1,
      Timestamp.Epoch
    )

  def mkJobLog(j: docspell.scheduler.Job[String], jl: Vector[RJobLog]): JobAndLog =
    JobAndLog(mkJob(j), jl.map(r => JobLogEvent(r.created, r.level, r.message)).toList)
}
