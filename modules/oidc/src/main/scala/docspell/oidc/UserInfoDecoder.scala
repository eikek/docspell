/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.oidc

import docspell.common.Ident

import io.circe.{Decoder, DecodingFailure}

/** Helpers for implementing `OnUserInfo`. */
object UserInfoDecoder {

  /** Find the value for `preferred_username` standard claim (see
    * https://openid.net/specs/openid-connect-basic-1_0.html#StandardClaims).
    */
  def preferredUsername: Decoder[Ident] =
    findSomeId("preferred_username")

  /** Looks recursively in the JSON for the first attribute with name `key` and returns
    * its value (expecting an Ident).
    */
  def findSomeId(key: String): Decoder[Ident] =
    Decoder.instance { cursor =>
      cursor.value
        .findAllByKey(key)
        .find(_.isString)
        .flatMap(_.asString)
        .toRight(s"No value found in JSON for key '$key'")
        .flatMap(normalizeUid)
        .left
        .map(msg => DecodingFailure(msg, Nil))
    }

  private def normalizeUid(uid: String): Either[String, Ident] =
    Ident(uid.filter(Ident.chars.contains))
      .flatMap(id =>
        if (id.nonEmpty) Right(id) else Left(s"Id '$uid' empty after normalizing!'")
      )

}
