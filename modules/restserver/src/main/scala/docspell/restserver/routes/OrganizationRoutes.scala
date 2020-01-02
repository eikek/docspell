package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import docspell.restserver.routes.ParamDecoder._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object OrganizationRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ GET -> Root :? FullQueryParamMatcher(full) =>
        val q = req.params.get("q").map(_.trim).filter(_.nonEmpty)
        if (full.getOrElse(false)) {
          for {
            data <- backend.organization.findAllOrg(user.account, q)
            resp <- Ok(OrganizationList(data.map(mkOrg).toList))
          } yield resp
        } else {
          for {
            data <- backend.organization.findAllOrgRefs(user.account, q)
            resp <- Ok(ReferenceList(data.map(mkIdName).toList))
          } yield resp
        }

      case req @ POST -> Root =>
        for {
          data   <- req.as[Organization]
          newOrg <- newOrg(data, user.account.collective)
          added  <- backend.organization.addOrg(newOrg)
          resp   <- Ok(basicResult(added, "New organization saved."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data   <- req.as[Organization]
          upOrg  <- changeOrg(data, user.account.collective)
          update <- backend.organization.updateOrg(upOrg)
          resp   <- Ok(basicResult(update, "Organization updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          delOrg <- backend.organization.deleteOrg(id, user.account.collective)
          resp   <- Ok(basicResult(delOrg, "Organization deleted."))
        } yield resp
    }
  }

}
