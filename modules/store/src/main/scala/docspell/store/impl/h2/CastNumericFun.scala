/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.impl.h2

import java.math.BigDecimal

/** This is used from within the H2 database! */
object CastNumericFun {
  def castToNumeric(str: String): BigDecimal =
    try new BigDecimal(str)
    catch {
      case _: Throwable => null
    }
}
