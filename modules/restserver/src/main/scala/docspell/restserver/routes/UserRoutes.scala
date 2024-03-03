/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.Login.OnAccountSourceConflict
import docspell.backend.auth.{AuthToken, Login}
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

  def apply[F[_]: Async](
      backend: BackendApp[F],
      loginConfig: Login.Config,
      user: AuthToken
  ): HttpRoutes[F] = {
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
            data.newPassword,
            expectedAccountSources(loginConfig)
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
            OptionT
              .fromOption[F](
                users
                  .find(u => u.uid == id || u.login == id)
              )
              .semiflatMap(u => backend.collective.deleteUser(u.uid))
              .getOrElse(UpdateResult.notFound)
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
              NotFound(BasicResult(success = false, s"User '${username.id}' not found"))
          }
        } yield resp
    }
  }

  def admin[F[_]: Async](
      backend: BackendApp[F],
      loginConfig: Login.Config
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "resetPassword" =>
      for {
        input <- req.as[ResetPassword]
        result <- backend.collective.resetPassword(
          input.account,
          expectedAccountSources(loginConfig)
        )
        resp <- Ok(result match {
          case OCollective.PassResetResult.Success(np) =>
            ResetPasswordResult(success = true, np, "Password updated")
          case OCollective.PassResetResult.NotFound =>
            ResetPasswordResult(
              success = false,
              Password(""),
              "Password update failed. User not found."
            )
          case OCollective.PassResetResult.InvalidSource(source) =>
            ResetPasswordResult(
              success = false,
              Password(""),
              s"Password update failed. User has unexpected source: $source. Passwords are managed externally."
            )
        })
      } yield resp
    }
  }

  private def expectedAccountSources(loginConfig: Login.Config): Set[AccountSource] =
    loginConfig.onAccountSourceConflict match {
      case OnAccountSourceConflict.Fail    => Set(AccountSource.Local)
      case OnAccountSourceConflict.Convert => AccountSource.all.toList.toSet
    }
}
