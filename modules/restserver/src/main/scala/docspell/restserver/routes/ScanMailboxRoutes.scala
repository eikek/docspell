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

object ScanMailboxRoutes {

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    val ut  = backend.userTask
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "startonce" =>
        for {
          data <- req.as[ScanMailboxSettings]
          task = makeTask(user.account, data)
          res <-
            ut.executeNow(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Submitted successfully."))
          resp <- Ok(res)
        } yield resp

      case GET -> Root =>
        for {
          task <- ut.getScanMailbox(user.account)
          res  <- taskToSettings(user.account, backend, task)
          resp <- Ok(res)
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[ScanMailboxSettings]
          task = makeTask(user.account, data)
          res <-
            ut.submitScanMailbox(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Saved successfully."))
          resp <- Ok(res)
        } yield resp
    }
  }

  def makeTask(
      user: AccountId,
      settings: ScanMailboxSettings
  ): UserTask[ScanMailboxArgs] =
    UserTask(
      settings.id,
      ScanMailboxArgs.taskName,
      settings.enabled,
      settings.schedule,
      ScanMailboxArgs(
        user,
        settings.imapConnection,
        settings.folders,
        settings.receivedSinceHours.map(_.toLong).map(Duration.hours),
        settings.targetFolder,
        settings.deleteMail,
        settings.direction
      )
    )

  def taskToSettings[F[_]: Sync](
      account: AccountId,
      backend: BackendApp[F],
      task: UserTask[ScanMailboxArgs]
  ): F[ScanMailboxSettings] =
    for {
      conn <-
        backend.mail
          .getImapSettings(account, None)
          .map(
            _.find(_.name == task.args.imapConnection)
              .map(_.name)
          )
    } yield ScanMailboxSettings(
      task.id,
      task.enabled,
      conn.getOrElse(Ident.unsafe("")),
      task.args.folders, //folders
      task.timer,
      task.args.receivedSince.map(_.hours.toInt),
      task.args.targetFolder,
      task.args.deleteMail,
      task.args.direction
    )
}
