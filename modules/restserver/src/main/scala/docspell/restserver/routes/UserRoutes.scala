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
            user.account,
            data.currentPassword,
            data.newPassword
          )
          resp <- Ok(basicResult(res))
        } yield resp

      case GET -> Root =>
        for {
          all <- backend.collective.listUser(user.account.collective)
          res <- Ok(UserList(all.map(mkUser).toList))
        } yield res

      case req @ POST -> Root =>
        for {
          data <- req.as[User]
          nuser <- newUser(data, user.account.collective)
          added <- backend.collective.add(nuser)
          resp <- Ok(basicResult(added, "User created."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data <- req.as[User]
          nuser = changeUser(data, user.account.collective)
          update <- backend.collective.update(nuser)
          resp <- Ok(basicResult(update, "User updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          ar <- backend.collective.deleteUser(id, user.account.collective)
          resp <- Ok(basicResult(ar, "User deleted."))
        } yield resp

      case GET -> Root / Ident(username) / "deleteData" =>
        for {
          data <- backend.collective.getDeleteUserData(
            AccountId(user.account.collective, username)
          )
          resp <- Ok(
            DeleteUserData(data.ownedFolders, data.sentMails, data.shares)
          )
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
