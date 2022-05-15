/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joexapi.client

import cats.effect._
import cats.implicits._

import docspell.common.{Ident, LenientUri}
import docspell.joexapi.model.{AddonSupport, BasicResult}

import org.http4s.blaze.client.BlazeClientBuilder
import org.http4s.circe.CirceEntityDecoder
import org.http4s.client.Client
import org.http4s.{Method, Request, Uri}

trait JoexClient[F[_]] {

  def notifyJoex(base: LenientUri): F[BasicResult]

  def notifyJoexIgnoreErrors(base: LenientUri): F[Unit]

  def cancelJob(base: LenientUri, job: Ident): F[BasicResult]

  def getAddonSupport(base: LenientUri): F[AddonSupport]
}

object JoexClient {

  def apply[F[_]: Async](client: Client[F]): JoexClient[F] =
    new JoexClient[F] with CirceEntityDecoder {
      private[this] val logger = docspell.logging.getLogger[F]

      def getAddonSupport(base: LenientUri): F[AddonSupport] = {
        val getUrl = base / "api" / "v1" / "addon" / "config"
        val req = Request[F](Method.GET, uri(getUrl))
        logger.debug(s"Getting addon support") *>
          client.expect[AddonSupport](req)
      }

      def notifyJoex(base: LenientUri): F[BasicResult] = {
        val notifyUrl = base / "api" / "v1" / "notify"
        val req = Request[F](Method.POST, uri(notifyUrl))
        logger.debug(s"Notify joex at ${notifyUrl.asString}") *>
          client.expect[BasicResult](req)
      }

      def notifyJoexIgnoreErrors(base: LenientUri): F[Unit] =
        notifyJoex(base).attempt.flatMap {
          case Right(BasicResult(succ, msg)) =>
            if (succ) ().pure[F]
            else
              logger.warn(
                s"Notifying Joex instance '${base.asString}' returned with failure: $msg"
              )
          case Left(ex) =>
            logger.warn(
              s"Notifying Joex instance '${base.asString}' failed: ${ex.getMessage}"
            )
        }

      def cancelJob(base: LenientUri, job: Ident): F[BasicResult] = {
        val cancelUrl = base / "api" / "v1" / "job" / job.id / "cancel"
        val req = Request[F](Method.POST, uri(cancelUrl))
        client.expect[BasicResult](req)
      }

      private def uri(u: LenientUri): Uri =
        Uri.unsafeFromString(u.asString)
    }

  def resource[F[_]: Async]: Resource[F, JoexClient[F]] =
    BlazeClientBuilder[F].resource.map(apply[F])
}
