package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OCollective
import docspell.common.MakePreviewArgs
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s._

import com.github.eikek.calev.CalEvent
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object CollectiveRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "insights" =>
        for {
          ins  <- backend.collective.insights(user.account.collective)
          resp <- Ok(Conversions.mkItemInsights(ins))
        } yield resp

      case GET -> Root / "tagcloud" =>
        for {
          cloud <- backend.collective.tagCloud(user.account.collective)
          resp  <- Ok(Conversions.mkTagCloud(cloud))
        } yield resp

      case req @ POST -> Root / "settings" =>
        for {
          settings <- req.as[CollectiveSettings]
          sett = OCollective.Settings(
            settings.language,
            settings.integrationEnabled,
            Some(
              OCollective.Classifier(
                settings.classifier.enabled,
                settings.classifier.schedule,
                settings.classifier.itemCount
              )
            )
          )
          res <-
            backend.collective
              .updateSettings(user.account.collective, sett)
          resp <- Ok(Conversions.basicResult(res, "Settings updated."))
        } yield resp

      case GET -> Root / "settings" =>
        for {
          settDb <- backend.collective.findSettings(user.account.collective)
          sett = settDb.map(c =>
            CollectiveSettings(
              c.language,
              c.integrationEnabled,
              ClassifierSetting(
                c.classifier.exists(_.enabled),
                c.classifier.map(_.itemCount).getOrElse(0),
                c.classifier
                  .map(_.schedule)
                  .getOrElse(CalEvent.unsafe("*-1/3-01 01:00:00"))
              )
            )
          )
          resp <- sett.toResponse()
        } yield resp

      case GET -> Root / "contacts" :? QueryParam.QueryOpt(q) +& QueryParam
            .ContactKindOpt(kind) =>
        for {
          res <-
            backend.collective
              .getContacts(user.account.collective, q.map(_.q), kind)
              .take(50)
              .compile
              .toList
          resp <- Ok(ContactList(res.map(Conversions.mkContact)))
        } yield resp

      case POST -> Root / "classifier" / "startonce" =>
        for {
          _    <- backend.collective.startLearnClassifier(user.account.collective)
          resp <- Ok(BasicResult(true, "Task submitted"))
        } yield resp

      case POST -> Root / "previews" =>
        for {
          res <- backend.collective.generatePreviews(
            MakePreviewArgs.StoreMode.Replace,
            user.account,
            true
          )
          resp <- Ok(
            Conversions.basicResult(res, "Generate all previews task submitted.")
          )
        } yield resp

      case GET -> Root =>
        for {
          collDb <- backend.collective.find(user.account.collective)
          coll = collDb.map(c => Collective(c.id, c.state, c.created))
          resp <- coll.toResponse()
        } yield resp
    }
  }

}
