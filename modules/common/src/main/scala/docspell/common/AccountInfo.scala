/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class AccountInfo(
    collectiveId: CollectiveId,
    collective: Ident,
    userId: Ident,
    login: Ident
) {

  def asAccountId: AccountId =
    AccountId(collective, login)

  def asString: String =
    s"${collectiveId.value}/${collective.id}/${userId.id}/${login.id}"
}

object AccountInfo {

  implicit val jsonDecoder: Decoder[AccountInfo] = deriveDecoder
  implicit val jsonEncoder: Encoder[AccountInfo] = deriveEncoder

  def parse(str: String): Either[String, AccountInfo] = {
    val input = str.replaceAll("\\s+", "").trim
    val invalid: Either[String, AccountInfo] =
      Left(s"Cannot parse account info: $str")

    input.split('/').toList match {
      case collId :: collName :: userId :: login :: Nil =>
        for {
          cid <- collId.toLongOption.toRight(s"Invalid collective id: $collId")
          cn <- Ident.fromString(collName)
          uid <- Ident.fromString(userId)
          un <- Ident.fromString(login)
        } yield AccountInfo(CollectiveId(cid), cn, uid, un)
      case _ =>
        invalid
    }
  }
}
