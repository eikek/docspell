/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.oidc

import docspell.common._

import scodec.bits.ByteVector

final case class ProviderConfig(
    providerId: Ident,
    clientId: String,
    clientSecret: String,
    scope: String,
    authorizeUrl: LenientUri,
    tokenUrl: LenientUri,
    userUrl: Option[LenientUri],
    signKey: ByteVector,
    sigAlgo: SignatureAlgo
)

object ProviderConfig {

  def github(clientId: String, clientSecret: String) =
    ProviderConfig(
      Ident.unsafe("github"),
      clientId,
      clientSecret,
      "profile",
      LenientUri.unsafe("https://github.com/login/oauth/authorize"),
      LenientUri.unsafe("https://github.com/login/oauth/access_token"),
      Some(LenientUri.unsafe("https://api.github.com/user")),
      ByteVector.empty,
      SignatureAlgo.RS256
    )
}
