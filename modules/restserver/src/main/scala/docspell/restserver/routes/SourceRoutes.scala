package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.ResponseGenerator
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object SourceRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config, user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          all  <- backend.source.findAll(user.account)
          res  <- Ok(SourceList(all.map(mkSource).toList))
        } yield res

      case req @ POST -> Root =>
        for {
          data  <- req.as[Source]
          src   <- newSource(data, user.account.collective)
          added <- backend.source.add(src)
          resp  <- Ok(basicResult(added, "Source added."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data    <- req.as[Source]
          src     =  changeSource(data, user.account.collective)
          updated <- backend.source.update(src)
          resp    <- Ok(basicResult(updated, "Source updated."))
        } yield resp

      case DELETE -> Root / Ident(id)  =>
        for {
          del  <- backend.source.delete(id, user.account.collective)
          resp <- Ok(basicResult(del, "Source deleted."))
        } yield resp
    }
  }

}
