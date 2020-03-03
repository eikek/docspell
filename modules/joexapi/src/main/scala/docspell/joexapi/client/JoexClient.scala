package docspell.joexapi.client

import cats.implicits._
import cats.effect._
import docspell.common.{Ident, LenientUri}
import org.http4s.{Method, Request, Uri}
import org.http4s.client.Client
import org.http4s.client.blaze.BlazeClientBuilder
import scala.concurrent.ExecutionContext

import org.log4s.getLogger

trait JoexClient[F[_]] {

  def notifyJoex(base: LenientUri): F[Unit]

  def notifyJoexIgnoreErrors(base: LenientUri): F[Unit]

  def cancelJob(base: LenientUri, job: Ident): F[Unit]

}

object JoexClient {

  private[this] val logger = getLogger

  def apply[F[_]: Sync](client: Client[F]): JoexClient[F] =
    new JoexClient[F] {
      def notifyJoex(base: LenientUri): F[Unit] = {
        val notifyUrl = base / "api" / "v1" / "notify"
        val req = Request[F](Method.POST, uri(notifyUrl))
        client.expect[String](req).map(_ => ())
      }

      def notifyJoexIgnoreErrors(base: LenientUri): F[Unit] =
        notifyJoex(base).attempt.map {
          case Right(()) => ()
          case Left(ex) =>
            logger.warn(s"Notifying Joex instance '${base.asString}' failed: ${ex.getMessage}")
            ()
        }

      def cancelJob(base: LenientUri, job: Ident): F[Unit] = {
        val cancelUrl = base / "api" / "v1" / "job" / job.id / "cancel"
        val req = Request[F](Method.POST, uri(cancelUrl))
        client.expect[String](req).map(_ => ())
      }

      private def uri(u: LenientUri): Uri =
        Uri.unsafeFromString(u.asString)
    }

  def resource[F[_]: ConcurrentEffect](ec: ExecutionContext): Resource[F, JoexClient[F]] =
    BlazeClientBuilder[F](ec).resource.map(apply[F])
}