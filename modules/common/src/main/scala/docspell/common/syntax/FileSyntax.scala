/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
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
