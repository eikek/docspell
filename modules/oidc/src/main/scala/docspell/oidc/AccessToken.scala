/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.oidc

import io.circe.Decoder
import scodec.bits.ByteVector

/** The response from an authorization server to the "token request". The redirect request
  * contains an authorization code that is used to request tokens at the authorization
  * server. The server then responds with this structure.
  *
  * @param accessToken
  *   the jwt encoded access token
  * @param tokenType
  *   the token type, is always 'Bearer'
  * @param expiresIn
  *   when it expires (in seconds from unix epoch)
  * @param refreshToken
  *   optional refresh token
  * @param refreshExpiresIn
  *   optional expiry time for the refresh token (in seconds from unix epoch)
  * @param sessionState
  *   an optional session state
  * @param scope
  *   the scope as requested. this must be present for OpenId Connect, but not necessarily
  *   for OAuth2
  */
final case class AccessToken(
    accessToken: String,
    tokenType: String,
    expiresIn: Option[Long],
    refreshToken: Option[String],
    refreshExpiresIn: Option[Long],
    sessionState: Option[String],
    scope: Option[String]
) {

  /** Decodes the `accessToken` as a JWT and validates it given the key and expected
    * signature algorithm.
    */
  def decodeToken(key: ByteVector, algo: SignatureAlgo): Either[String, Jwt] =
    SignatureAlgo.decoder(key, algo)(accessToken).left.map(_.getMessage)
}

object AccessToken {

  implicit val decoder: Decoder[AccessToken] =
    Decoder.instance { c =>
      for {
        atoken  <- c.get[String]("access_token")
        ttype   <- c.get[String]("token_type")
        expire  <- c.get[Option[Long]]("expires_in")
        rtoken  <- c.get[Option[String]]("refresh_token")
        rexpire <- c.get[Option[Long]]("refresh_expires_in")
        sstate  <- c.get[Option[String]]("session_state")
        scope   <- c.get[Option[String]]("scope")
      } yield AccessToken(atoken, ttype, expire, rtoken, rexpire, sstate, scope)
    }
}
