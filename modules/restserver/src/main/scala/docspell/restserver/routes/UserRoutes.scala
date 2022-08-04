/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OCollective
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import docspell.store.UpdateResult
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object UserRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "changePassword" =>
        for {
          data <- req.as[PasswordChange]
          res <- backend.collective.changePassword(
            user.account.collectiveId,
            user.account.userId,
            data.currentPassword,
            data.newPassword
          )
          resp <- Ok(basicResult(res))
        } yield resp

      case GET -> Root =>
        for {
          all <- backend.collective.listUser(user.account.collectiveId)
          res <- Ok(UserList(all.map(mkUser).toList))
        } yield res

      case req @ POST -> Root =>
        for {
          data <- req.as[User]
          nuser <- newUser(data, user.account.collectiveId)
          added <- backend.collective.add(nuser)
          resp <- Ok(basicResult(added, "User created."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data <- req.as[User]
          nuser = changeUser(data, user.account.collectiveId)
          update <- backend.collective.update(nuser)
          resp <- Ok(basicResult(update, "User updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          users <- backend.collective.listUser(user.account.collectiveId)
          ar <-
            if (users.exists(_.uid == id)) backend.collective.deleteUser(id)
            else UpdateResult.notFound.pure[F]
          resp <- Ok(basicResult(ar, "User deleted."))
        } yield resp

      case GET -> Root / Ident(username) / "deleteData" =>
        for {
          users <- backend.collective.listUser(user.account.collectiveId)
          userToDelete = users.find(u => u.login == username || u.uid == username)
          resp <- userToDelete match {
            case Some(user) =>
              backend.collective
                .getDeleteUserData(user.cid, user.uid)
                .flatMap(data =>
                  Ok(DeleteUserData(data.ownedFolders, data.sentMails, data.shares))
                )

            case None =>
              NotFound(BasicResult(false, s"User '${username.id}' not found"))
          }
        } yield resp
    }
  }

  def admin[F[_]: Async](backend: BackendApp[F]): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "resetPassword" =>
      for {
        input <- req.as[ResetPassword]
        result <- backend.collective.resetPassword(input.account)
        resp <- Ok(result match {
          case OCollective.PassResetResult.Success(np) =>
            ResetPasswordResult(true, np, "Password updated")
          case OCollective.PassResetResult.NotFound =>
            ResetPasswordResult(
              false,
              Password(""),
              "Password update failed. User not found."
            )
          case OCollective.PassResetResult.UserNotLocal =>
            ResetPasswordResult(
              false,
              Password(""),
              "Password update failed. User is not local, passwords are managed externally."
            )
        })
      } yield resp
    }
  }
}
