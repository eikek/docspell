/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert
import java.nio.charset.Charset

import scodec.bits.ByteVector

@FunctionalInterface
trait SanitizeHtml {

  /** The given `bytes' are html which can be modified to strip out unwanted content.
    *
    * The result should use the same character encoding as the given charset implies, or
    * utf8 if not specified.
    */
  def apply(bytes: ByteVector, charset: Option[Charset]): ByteVector

}

object SanitizeHtml {

  val none: SanitizeHtml =
    (bv, _) => bv

}
