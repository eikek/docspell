package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.{Ident, ItemState}
import org.http4s.HttpRoutes
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import docspell.restapi.model._
import docspell.common.syntax.all._
import docspell.restserver.conv.Conversions
import org.log4s._

object ItemRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "search" =>
        for {
          mask  <- req.as[ItemSearch]
          _     <- logger.ftrace(s"Got search mask: $mask")
          query = Conversions.mkQuery(mask, user.account.collective)
          _     <- logger.ftrace(s"Running query: $query")
          items <- backend.item.findItems(query, 100)
          resp  <- Ok(Conversions.mkItemList(items))
        } yield resp

      case GET -> Root / Ident(id) =>
        for {
          item   <- backend.item.findItem(id, user.account.collective)
          result = item.map(Conversions.mkItemDetail)
          resp   <- result.map(r => Ok(r)).getOrElse(NotFound(BasicResult(false, "Not found.")))
        } yield resp

      case POST -> Root / Ident(id) / "confirm" =>
        for {
          res  <- backend.item.setState(id, ItemState.Confirmed, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item data confirmed"))
        } yield resp

      case POST -> Root / Ident(id) / "unconfirm" =>
        for {
          res  <- backend.item.setState(id, ItemState.Created, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item back to created."))
        } yield resp

      case req @ POST -> Root / Ident(id) / "tags" =>
        for {
          tags <- req.as[ReferenceList].map(_.items)
          res  <- backend.item.setTags(id, tags.map(_.id), user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Tags updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "direction" =>
        for {
          dir  <- req.as[DirectionValue]
          res  <- backend.item.setDirection(id, dir.direction, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Direction updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "corrOrg" =>
        for {
          idref <- req.as[OptionalId]
          res   <- backend.item.setCorrOrg(id, idref.id, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "corrPerson" =>
        for {
          idref <- req.as[OptionalId]
          res   <- backend.item.setCorrPerson(id, idref.id, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "concPerson" =>
        for {
          idref <- req.as[OptionalId]
          res   <- backend.item.setConcPerson(id, idref.id, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Concerned person updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "concEquipment" =>
        for {
          idref <- req.as[OptionalId]
          res   <- backend.item.setConcEquip(id, idref.id, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "notes" =>
        for {
          text <- req.as[OptionalText]
          res  <- backend.item.setNotes(id, text.text, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "name" =>
        for {
          text <- req.as[OptionalText]
          res  <- backend.item.setName(id, text.text.getOrElse(""), user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "duedate" =>
        for {
          date <- req.as[OptionalDate]
          _    <- logger.fdebug(s"Setting item due date to ${date.date}")
          res  <- backend.item.setItemDueDate(id, date.date, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item due date updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "date" =>
        for {
          date <- req.as[OptionalDate]
          _    <- logger.fdebug(s"Setting item date to ${date.date}")
          res  <- backend.item.setItemDate(id, date.date, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item date updated"))
        } yield resp

      case GET -> Root / Ident(id) / "proposals" =>
        for {
          ml   <- backend.item.getProposals(id, user.account.collective)
          ip   = Conversions.mkItemProposals(ml)
          resp <- Ok(ip)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          n    <- backend.item.delete(id, user.account.collective)
          res  = BasicResult(n > 0, if (n > 0) "Item deleted" else "Item deletion failed.")
          resp <- Ok(res)
        } yield resp
    }
  }
}
