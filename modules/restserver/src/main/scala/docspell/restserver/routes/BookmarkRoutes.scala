package docspell.restserver.routes

import docspell.backend.auth.AuthToken
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import cats.effect.Async
import docspell.backend.ops.OQueryBookmarks
import docspell.restapi.model.BookmarkedQuery
import docspell.backend.BackendApp
import cats.implicits._
import docspell.restserver.conv.Conversions
import docspell.common.Ident

object BookmarkRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], token: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          all <- backend.bookmarks.getAll(token.account)
          resp <- Ok(all.map(convert.toApi))
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[BookmarkedQuery]
          res <- backend.bookmarks.create(token.account, convert.toModel(data))
          resp <- Ok(Conversions.basicResult(res, "Bookmark created"))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data <- req.as[BookmarkedQuery]
          res <- backend.bookmarks.update(token.account, data.id, convert.toModel(data))
          resp <- Ok(Conversions.basicResult(res, "Bookmark updated"))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.bookmarks.delete(token.account, id).attempt
          resp <- Ok(Conversions.basicResult(res, "Bookmark deleted"))
        } yield resp
    }
  }

  object convert {
    def toApi(b: OQueryBookmarks.Bookmark): BookmarkedQuery =
      BookmarkedQuery(b.id, b.name, b.label, b.query, b.personal, b.created)

    def toModel(b: BookmarkedQuery): OQueryBookmarks.NewBookmark =
      OQueryBookmarks.NewBookmark(b.name, b.label, b.query, b.personal)
  }
}
