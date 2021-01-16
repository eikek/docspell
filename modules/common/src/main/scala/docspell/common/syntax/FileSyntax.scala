package docspell.common.syntax

import java.nio.file.Path

trait FileSyntax {

  implicit final class PathOps(p: Path) {

    def absolutePath: Path =
      p.normalize().toAbsolutePath

    def absolutePathAsString: String =
      absolutePath.toString

    def /(next: String): Path =
      p.resolve(next)
  }
}

object FileSyntax extends FileSyntax
