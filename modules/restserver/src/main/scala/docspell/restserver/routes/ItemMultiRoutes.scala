package docspell.restserver.routes

import cats.ApplicativeError
import cats.MonadError
import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.{Ident, ItemState}
import docspell.restapi.model._
import docspell.restserver.conv.Conversions

import io.circe.DecodingFailure
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ItemMultiRoutes {
//  private[this] val logger = getLogger

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ PUT -> Root / "confirm" =>
        for {
          json <- req.as[IdList]
          data <- readIds[F](json.ids)
          res <- backend.item.setStates(
            data,
            ItemState.Confirmed,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Item data confirmed"))
        } yield resp

      case req @ PUT -> Root / "unconfirm" =>
        for {
          json <- req.as[IdList]
          data <- readIds[F](json.ids)
          res <- backend.item.setStates(
            data,
            ItemState.Created,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Item back to created."))
        } yield resp

      case req @ PUT -> Root / "tags" =>
        for {
          json  <- req.as[ItemsAndRefs]
          items <- readIds[F](json.items)
          tags  <- json.refs.traverse(readId[F])
          res   <- backend.item.setTagsMultipleItems(items, tags, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Tags updated"))
        } yield resp

      case req @ POST -> Root / "tags" =>
        for {
          json  <- req.as[ItemsAndRefs]
          items <- readIds[F](json.items)
          res <- backend.item.linkTagsMultipleItems(
            items,
            json.refs,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Tags added."))
        } yield resp

      case req @ PUT -> Root / "name" =>
        for {
          json  <- req.as[ItemsAndName]
          items <- readIds[F](json.items)
          res <- backend.item.setNameMultiple(
            items,
            json.name.notEmpty.getOrElse(""),
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Name updated"))
        } yield resp

      case req @ PUT -> Root / "folder" =>
        for {
          json  <- req.as[ItemsAndRef]
          items <- readIds[F](json.items)
          res   <- backend.item.setFolderMultiple(items, json.ref, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Folder updated"))
        } yield resp

      case req @ PUT -> Root / "direction" =>
        for {
          json  <- req.as[ItemsAndDirection]
          items <- readIds[F](json.items)
          res   <- backend.item.setDirection(items, json.direction, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Direction updated"))
        } yield resp

      case req @ PUT -> Root / "date" =>
        for {
          json  <- req.as[ItemsAndDate]
          items <- readIds[F](json.items)
          res   <- backend.item.setItemDate(items, json.date, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Item date updated"))
        } yield resp

      case req @ PUT -> Root / "duedate" =>
        for {
          json  <- req.as[ItemsAndDate]
          items <- readIds[F](json.items)
          res   <- backend.item.setItemDueDate(items, json.date, user.account.collective)
          resp  <- Ok(Conversions.basicResult(res, "Item due date updated"))
        } yield resp

      // case req @ PUT -> Root / "corrOrg" =>
      //   for {
      //     idref <- req.as[OptionalId]
      //     res   <- backend.item.setCorrOrg(id, idref.id, user.account.collective)
      //     resp  <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
      //   } yield resp

      // case req @ PUT -> Root / "corrPerson" =>
      //   for {
      //     idref <- req.as[OptionalId]
      //     res   <- backend.item.setCorrPerson(id, idref.id, user.account.collective)
      //     resp  <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
      //   } yield resp

      // case req @ PUT -> Root / "concPerson" =>
      //   for {
      //     idref <- req.as[OptionalId]
      //     res   <- backend.item.setConcPerson(id, idref.id, user.account.collective)
      //     resp  <- Ok(Conversions.basicResult(res, "Concerned person updated"))
      //   } yield resp

      // case req @ PUT -> Root / "concEquipment" =>
      //   for {
      //     idref <- req.as[OptionalId]
      //     res   <- backend.item.setConcEquip(id, idref.id, user.account.collective)
      //     resp  <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
      //   } yield resp

      // case req @ POST -> Root / "reprocess" =>
      //   for {
      //     data <- req.as[IdList]
      //     ids = data.ids.flatMap(s => Ident.fromString(s).toOption)
      //     _    <- logger.fdebug(s"Re-process item ${id.id}")
      //     res  <- backend.item.reprocess(id, ids, user.account, true)
      //     resp <- Ok(Conversions.basicResult(res, "Re-process task submitted."))
      //   } yield resp

      // case POST -> Root / "deleteAll" =>
      //   for {
      //     n <- backend.item.deleteItem(id, user.account.collective)
      //     res = BasicResult(n > 0, if (n > 0) "Item deleted" else "Item deletion failed.")
      //     resp <- Ok(res)
      //   } yield resp
    }
  }

  implicit final class OptionString(opt: Option[String]) {
    def notEmpty: Option[String] =
      opt.map(_.trim).filter(_.nonEmpty)
  }
  implicit final class StringOps(str: String) {
    def notEmpty: Option[String] =
      Option(str).notEmpty
  }

  private def readId[F[_]](
      id: String
  )(implicit F: ApplicativeError[F, Throwable]): F[Ident] =
    Ident
      .fromString(id)
      .fold(
        err => F.raiseError(DecodingFailure(err, Nil)),
        F.pure
      )

  private def readIds[F[_]](ids: List[String])(implicit
      F: MonadError[F, Throwable]
  ): F[NonEmptyList[Ident]] =
    ids.traverse(readId[F]).map(NonEmptyList.fromList).flatMap {
      case Some(nel) => nel.pure[F]
      case None =>
        F.raiseError(
          DecodingFailure("Empty list found, at least one element required", Nil)
        )
    }
}
