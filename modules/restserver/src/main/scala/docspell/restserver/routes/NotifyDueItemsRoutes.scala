package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.store.usertask._

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

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
      case GET -> Root / Ident(id) =>
        (for {
          task <- ut.findNotifyDueItems(id, user.account)
          res  <- OptionT.liftF(taskToSettings(user.account, backend, task))
          resp <- OptionT.liftF(Ok(res))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "startonce" =>
        for {
          data  <- req.as[NotificationSettings]
          newId <- Ident.randomId[F]
          task  <- makeTask(newId, cfg, user.account, data)
          res <-
            ut.executeNow(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Submitted successfully."))
          resp <- Ok(res)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <-
            ut.deleteTask(user.account, id)
              .attempt
              .map(Conversions.basicResult(_, "Deleted successfully"))
          resp <- Ok(res)
        } yield resp

      case req @ PUT -> Root =>
        def run(data: NotificationSettings) =
          for {
            task <- makeTask(data.id, cfg, user.account, data)
            res <-
              ut.submitNotifyDueItems(user.account, task)
                .attempt
                .map(Conversions.basicResult(_, "Saved successfully"))
            resp <- Ok(res)
          } yield resp
        for {
          data <- req.as[NotificationSettings]
          resp <-
            if (data.id.isEmpty) Ok(BasicResult(false, "Empty id is not allowed"))
            else run(data)
        } yield resp

      case req @ POST -> Root =>
        for {
          data  <- req.as[NotificationSettings]
          newId <- Ident.randomId[F]
          task  <- makeTask(newId, cfg, user.account, data)
          res <-
            ut.submitNotifyDueItems(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Saved successfully."))
          resp <- Ok(res)
        } yield resp

      case GET -> Root =>
        ut.getNotifyDueItems(user.account)
          .evalMap(task => taskToSettings(user.account, backend, task))
          .compile
          .toVector
          .map(v => NotificationSettingsList(v.toList))
          .flatMap(Ok(_))
    }
  }

  def makeTask[F[_]: Sync](
      id: Ident,
      cfg: Config,
      user: AccountId,
      settings: NotificationSettings
  ): F[UserTask[NotifyDueItemsArgs]] =
    Sync[F].pure(
      UserTask(
        id,
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
          .getSmtpSettings(account, None)
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
