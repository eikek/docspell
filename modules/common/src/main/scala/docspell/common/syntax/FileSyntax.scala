/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common.syntax

import fs2.io.file.Path

trait FileSyntax {

  implicit final class PathOps(p: Path) {

    def absolutePath: Path =
      p.absolute

    def absolutePathAsString: String =
      absolutePath.toString
  }
}

object FileSyntax extends FileSyntax
