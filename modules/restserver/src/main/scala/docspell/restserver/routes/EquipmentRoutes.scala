package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.QueryParam

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object EquipmentRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QueryParam.QueryOpt(q) =>
        for {
          data <- backend.equipment.findAll(user.account, q.map(_.q))
          resp <- Ok(EquipmentList(data.map(mkEquipment).toList))
        } yield resp

      case req @ POST -> Root =>
        for {
          data  <- req.as[Equipment]
          equip <- newEquipment(data, user.account.collective)
          res   <- backend.equipment.add(equip)
          resp  <- Ok(basicResult(res, "Equipment created"))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data  <- req.as[Equipment]
          equip <- changeEquipment(data, user.account.collective)
          res   <- backend.equipment.update(equip)
          resp  <- Ok(basicResult(res, "Equipment updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          del  <- backend.equipment.delete(id, user.account.collective)
          resp <- Ok(basicResult(del, "Equipment deleted."))
        } yield resp

      case GET -> Root / Ident(id) =>
        (for {
          equip <- OptionT(backend.equipment.find(user.account, id))
          resp  <- OptionT.liftF(Ok(mkEquipment(equip)))
        } yield resp).getOrElseF(NotFound())
    }
  }
}
