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

object NotifyDueItemsRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    val ut  = backend.userTask
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          task <- ut.getNotifyDueItems(user.account)
          resp <- Ok(convert(task))
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[NotificationSettings]
          task = makeTask(user.account, data)
          res <- ut
            .submitNotifyDueItems(user.account, task)
            .attempt
            .map(Conversions.basicResult(_, "Update ok."))
          resp <- Ok(res)
        } yield resp
    }
  }

  def convert(task: UserTask[NotifyDueItemsArgs]): NotificationData =
    NotificationData(taskToSettings(task), None, None)

  def makeTask(
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
        settings.remindDays,
        settings.tagsInclude.map(Ident.unsafe),
        settings.tagsExclude.map(Ident.unsafe)
      )
    )

  def taskToSettings(task: UserTask[NotifyDueItemsArgs]): NotificationSettings =
    NotificationSettings(
      task.id,
      task.enabled,
      task.args.smtpConnection,
      task.args.recipients,
      task.timer,
      task.args.remindDays,
      task.args.tagsInclude.map(_.id),
      task.args.tagsExclude.map(_.id)
    )
}
