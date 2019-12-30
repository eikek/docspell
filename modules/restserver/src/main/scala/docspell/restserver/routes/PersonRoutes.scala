package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.common.syntax.all._
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import docspell.restserver.routes.ParamDecoder._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s._

object PersonRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? FullQueryParamMatcher(full) =>
        if (full.getOrElse(false)) {
          for {
            data <- backend.organization.findAllPerson(user.account)
            resp <- Ok(PersonList(data.map(mkPerson).toList))
          } yield resp
        } else {
          for {
            data <- backend.organization.findAllPersonRefs(user.account)
            resp <- Ok(ReferenceList(data.map(mkIdName).toList))
          } yield resp
        }

      case req @ POST -> Root =>
        for {
          data   <- req.as[Person]
          newPer <- newPerson(data, user.account.collective)
          added  <- backend.organization.addPerson(newPer)
          resp   <- Ok(basicResult(added, "New person saved."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data   <- req.as[Person]
          upPer  <- changePerson(data, user.account.collective)
          update <- backend.organization.updatePerson(upPer)
          resp   <- Ok(basicResult(update, "Person updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          _      <- logger.fdebug(s"Deleting person ${id.id}")
          delOrg <- backend.organization.deletePerson(id, user.account.collective)
          resp   <- Ok(basicResult(delOrg, "Person deleted."))
        } yield resp
    }
  }

}
