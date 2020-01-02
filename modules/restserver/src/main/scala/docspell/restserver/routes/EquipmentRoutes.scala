package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object EquipmentRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ GET -> Root =>
        val q = req.params.get("q").map(_.trim).filter(_.nonEmpty)
        for {
          data <- backend.equipment.findAll(user.account, q)
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
          equip = changeEquipment(data, user.account.collective)
          res   <- backend.equipment.update(equip)
          resp  <- Ok(basicResult(res, "Equipment updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          del  <- backend.equipment.delete(id, user.account.collective)
          resp <- Ok(basicResult(del, "Equipment deleted."))
        } yield resp
    }
  }
}
