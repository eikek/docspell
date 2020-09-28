package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restapi.model._
import docspell.restserver.http4s._

import org.http4s.HttpRoutes
//import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import docspell.store.records.RCustomField

object CustomFieldRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          fs <- backend.customFields.findAll(user.account.collective)
          res <- Ok(CustomFieldList(fs.map(convertField).toList))
        } yield res
    }
  }


  private def convertField(f: RCustomField): CustomField =
    CustomField(f.id, f.name, f.ftype, f.created)
}
