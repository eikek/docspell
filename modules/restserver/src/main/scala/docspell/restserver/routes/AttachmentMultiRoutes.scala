package docspell.restserver.routes

import cats.effect.Effect
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restapi.model._
import docspell.restserver.conv.MultiIdSupport

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object AttachmentMultiRoutes extends MultiIdSupport {

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {

    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "delete" =>
      for {
        json        <- req.as[IdList]
        attachments <- readIds[F](json.ids)
        n           <- backend.item.deleteAttachmentMultiple(attachments, user.account.collective)
        res = BasicResult(
          n > 0,
          if (n > 0) "Attachment(s) deleted" else "Attachment deletion failed."
        )
        resp <- Ok(res)
      } yield resp
    }
  }

}
