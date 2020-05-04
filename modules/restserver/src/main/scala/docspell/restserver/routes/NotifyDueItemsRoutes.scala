package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restapi.model._
import docspell.store.usertask._
import docspell.restserver.conv.Conversions
import docspell.restserver.Config

object NotifyDueItemsRoutes {

  def apply[F[_]: Effect](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    val ut  = backend.userTask
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "startonce" =>
        for {
          data <- req.as[NotificationSettings]
          task = makeTask(cfg, user.account, data)
          res <-
            ut.executeNow(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Submitted successfully."))
          resp <- Ok(res)
        } yield resp

      case GET -> Root =>
        for {
          task <- ut.getNotifyDueItems(user.account)
          res  <- taskToSettings(user.account, backend, task)
          resp <- Ok(res)
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[NotificationSettings]
          task = makeTask(cfg, user.account, data)
          res <-
            ut.submitNotifyDueItems(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Saved successfully."))
          resp <- Ok(res)
        } yield resp
    }
  }

  def makeTask(
      cfg: Config,
      user: AccountId,
      settings: NotificationSettings
  ): UserTask[NotifyDueItemsArgs] =
    UserTask(
      settings.id,
      NotifyDueItemsArgs.taskName,
      settings.enabled,
      settings.schedule,
      NotifyDueItemsArgs(
        user,
        settings.smtpConnection,
        settings.recipients,
        Some(cfg.baseUrl / "app" / "item"),
        settings.remindDays,
        if (settings.capOverdue) Some(settings.remindDays)
        else None,
        settings.tagsInclude.map(_.id),
        settings.tagsExclude.map(_.id)
      )
    )

  def taskToSettings[F[_]: Sync](
      account: AccountId,
      backend: BackendApp[F],
      task: UserTask[NotifyDueItemsArgs]
  ): F[NotificationSettings] =
    for {
      tinc <- backend.tag.loadAll(task.args.tagsInclude)
      texc <- backend.tag.loadAll(task.args.tagsExclude)
      conn <-
        backend.mail
          .getSettings(account, None)
          .map(
            _.find(_.name == task.args.smtpConnection)
              .map(_.name)
          )
    } yield NotificationSettings(
      task.id,
      task.enabled,
      conn.getOrElse(Ident.unsafe("")),
      task.args.recipients,
      task.timer,
      task.args.remindDays,
      task.args.daysBack.isDefined,
      tinc.map(Conversions.mkTag).toList,
      texc.map(Conversions.mkTag).toList
    )
}
