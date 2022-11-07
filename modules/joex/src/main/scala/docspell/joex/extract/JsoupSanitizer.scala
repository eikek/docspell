/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.extract

import java.nio.charset.Charset

import emil.BodyContent
import emil.jsoup._
import scodec.bits.ByteVector

object JsoupSanitizer {
  private val whitelist =
    EmailWhitelist.default.addAttributes(":all", "class")

  private val change =
    BodyClean.whitelistClean(whitelist)

  def clean(html: String): String =
    BodyClean.modifyContent(change)(BodyContent(html)).asString

  def clean(html: ByteVector, cs: Option[Charset]): ByteVector =
    BodyClean.modifyContent(change)(BodyContent(html, cs)).bytes
}
