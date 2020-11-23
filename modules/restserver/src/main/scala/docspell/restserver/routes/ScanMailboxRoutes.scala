package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.store.usertask._

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ScanMailboxRoutes {

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    val ut  = backend.userTask
    import dsl._

    HttpRoutes.of {
      case GET -> Root / Ident(id) =>
        (for {
          task <- ut.findScanMailbox(id, user.account)
          res  <- OptionT.liftF(taskToSettings(user.account, backend, task))
          resp <- OptionT.liftF(Ok(res))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "startonce" =>
        for {
          data  <- req.as[ScanMailboxSettings]
          newId <- Ident.randomId[F]
          task  <- makeTask(newId, user.account, data)
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
              .map(Conversions.basicResult(_, "Deleted successfully."))
          resp <- Ok(res)
        } yield resp

      case req @ PUT -> Root =>
        def run(data: ScanMailboxSettings) =
          for {
            task <- makeTask(data.id, user.account, data)
            res <-
              ut.submitScanMailbox(user.account, task)
                .attempt
                .map(Conversions.basicResult(_, "Saved successfully."))
            resp <- Ok(res)
          } yield resp
        for {
          data <- req.as[ScanMailboxSettings]
          resp <-
            if (data.id.isEmpty) Ok(BasicResult(false, "Empty id is not allowed"))
            else run(data)
        } yield resp

      case req @ POST -> Root =>
        for {
          data  <- req.as[ScanMailboxSettings]
          newId <- Ident.randomId[F]
          task  <- makeTask(newId, user.account, data)
          res <-
            ut.submitScanMailbox(user.account, task)
              .attempt
              .map(Conversions.basicResult(_, "Saved successfully."))
          resp <- Ok(res)
        } yield resp

      case GET -> Root =>
        ut.getScanMailbox(user.account)
          .evalMap(task => taskToSettings(user.account, backend, task))
          .compile
          .toVector
          .map(v => ScanMailboxSettingsList(v.toList))
          .flatMap(Ok(_))
    }
  }

  def makeTask[F[_]: Sync](
      id: Ident,
      user: AccountId,
      settings: ScanMailboxSettings
  ): F[UserTask[ScanMailboxArgs]] =
    Sync[F].pure(
      UserTask(
        id,
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
          settings.direction,
          settings.itemFolder,
          settings.fileFilter,
          settings.tags.map(_.items),
          settings.subjectFilter,
          settings.language
        )
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
      task.args.folders,
      task.timer,
      task.args.receivedSince.map(_.hours.toInt),
      task.args.targetFolder,
      task.args.deleteMail,
      task.args.direction,
      task.args.itemFolder,
      task.args.tags.map(StringList.apply),
      task.args.fileFilter,
      task.args.subjectFilter,
      task.args.language
    )
}
