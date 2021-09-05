/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.oidc

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common.Logger

import io.circe.Json
import org.http4s._
import org.http4s.headers.`Content-Type`
import org.http4s.implicits._
import org.log4s.getLogger

/** Once the authentication flow is completed, we get "some" json structure that contains
  * a claim about the user. From here it's to the user of this small library to complete
  * the request.
  *
  * Usually the json is searched for an account name and the account is then created in
  * the application, if it not already exists. The concrete response is up to the
  * application, the OAuth/OpenID Connect is done (successfully) at this point.
  */
trait OnUserInfo[F[_]] {

  /** Create a response given the request and the obtained user info data. The `userInfo`
    * may be retrieved from an JWT token or it is the response of querying the user-info
    * endpoint, depending on the configuration provided to `CodeFlowRoutes`. In the latter
    * case, the authorization server validated the token.
    *
    * If `userInfo` is empty, then some error occurred during the flow. The exact error
    * has been logged, but it is not given here.
    */
  def handle(
      req: Request[F],
      provider: ProviderConfig,
      userInfo: Option[Json]
  ): F[Response[F]]
}

object OnUserInfo {
  private[this] val log = getLogger

  def apply[F[_]](
      f: (Request[F], ProviderConfig, Option[Json]) => F[Response[F]]
  ): OnUserInfo[F] =
    (req: Request[F], cfg: ProviderConfig, userInfo: Option[Json]) =>
      f(req, cfg, userInfo)

  def logInfo[F[_]: Sync]: OnUserInfo[F] =
    OnUserInfo((_, _, json) =>
      Logger
        .log4s(log)
        .info(s"Got data: ${json.map(_.spaces2)}")
        .map(_ =>
          Response[F](Status.Ok)
            .withContentType(`Content-Type`(mediaType"application/json"))
            .withBodyStream(
              Stream.emits(json.getOrElse(Json.obj()).spaces2.getBytes.toSeq)
            )
        )
    )
}
