package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OSpace
import docspell.common._
import docspell.store.records.RSpace
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s._

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object SpaceRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QueryParam.QueryOpt(q) =>
        for {
          all  <- backend.space.findAll(user.account.collective, q.map(_.q))
          resp <- Ok(SpaceList(all.map(mkSpace).toList))
        } yield resp

      case req @ POST -> Root =>
        for {
          data   <- req.as[NewSpace]
          nspace <- newSpace(data, user.account)
          res    <- backend.space.add(nspace, Some(user.account.user))
          resp   <- Ok(Conversions.idResult(res, nspace.id, "Space successfully created."))
        } yield resp

      case GET -> Root / Ident(id) =>
        (for {
          space <- OptionT(backend.space.findById(id, user.account.collective))
          resp  <- OptionT.liftF(Ok(mkSpaceDetail(space)))
        } yield resp).getOrElseF(NotFound())

      case req @ PUT -> Root / Ident(id) =>
        for {
          data <- req.as[NewSpace]
          res  <- backend.space.changeName(id, user.account, data.name)
          resp <- Ok(mkSpaceChangeResult(res))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res  <- backend.space.delete(id, user.account)
          resp <- Ok(mkSpaceChangeResult(res))
        } yield resp

      case PUT -> Root / Ident(id) / "member" / Ident(userId) =>
        for {
          res  <- backend.space.addMember(id, user.account, userId)
          resp <- Ok(mkSpaceChangeResult(res))
        } yield resp

      case DELETE -> Root / Ident(id) / "member" / Ident(userId) =>
        for {
          res  <- backend.space.removeMember(id, user.account, userId)
          resp <- Ok(mkSpaceChangeResult(res))
        } yield resp
    }
  }

  private def newSpace[F[_]: Sync](ns: NewSpace, account: AccountId): F[RSpace] =
    RSpace.newSpace(ns.name, account)

  private def mkSpace(item: OSpace.SpaceItem): SpaceItem =
    SpaceItem(
      item.id,
      item.name,
      Conversions.mkIdName(item.owner),
      item.created
    )

  private def mkSpaceDetail(item: OSpace.SpaceDetail): SpaceDetail =
    SpaceDetail(
      item.id,
      item.name,
      Conversions.mkIdName(item.owner),
      item.created,
      item.members.map(Conversions.mkIdName)
    )

  private def mkSpaceChangeResult(r: OSpace.SpaceChangeResult): BasicResult =
    r match {
      case OSpace.SpaceChangeResult.Success =>
        BasicResult(true, "Successfully changed space.")
      case OSpace.SpaceChangeResult.NotFound =>
        BasicResult(false, "Space or user not found.")
      case OSpace.SpaceChangeResult.Forbidden =>
        BasicResult(false, "Not allowed to edit space.")
      case OSpace.SpaceChangeResult.Exists =>
        BasicResult(false, "The member already exists.")
    }
}
