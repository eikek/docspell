package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import org.http4s.HttpRoutes
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import ParamDecoder._
import docspell.common.Ident

object OrganizationRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config, user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F]{}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? FullQueryParamMatcher(full) =>
        if (full.getOrElse(false)) {
          for {
            data  <- backend.organization.findAllOrg(user.account)
            resp  <- Ok(OrganizationList(data.map(mkOrg).toList))
          } yield resp
        } else {
          for {
            data <- backend.organization.findAllOrgRefs(user.account)
            resp <- Ok(ReferenceList(data.map(mkIdName).toList))
          } yield resp
        }

      case req @ POST -> Root =>
        for {
          data   <- req.as[Organization]
          newOrg <- newOrg(data, user.account.collective)
          added  <- backend.organization.addOrg(newOrg)
          resp  <- Ok(basicResult(added, "New organization saved."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data   <- req.as[Organization]
          upOrg  <- changeOrg(data, user.account.collective)
          update <- backend.organization.updateOrg(upOrg)
          resp   <- Ok(basicResult(update, "Organization updated."))
        } yield resp

      case DELETE -> Root / Ident(id)  =>
        for {
          delOrg  <- backend.organization.deleteOrg(id, user.account.collective)
          resp    <- Ok(basicResult(delOrg, "Organization deleted."))
        } yield resp
    }
  }

}
