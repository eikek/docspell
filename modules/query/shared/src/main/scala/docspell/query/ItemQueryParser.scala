package docspell.query

import cats.data.NonEmptyList

import docspell.query.internal.ExprParser
import docspell.query.internal.ExprUtil

object ItemQueryParser {

  def parse(input: String): Either[ParseFailure, ItemQuery] =
    if (input.isEmpty)
      Left(
        ParseFailure("", 0, NonEmptyList.of(ParseFailure.SimpleMessage(0, "No input.")))
      )
    else {
      val in = if (input.charAt(0) == '(') input else s"(& $input )"
      ExprParser
        .parseQuery(in)
        .left
        .map(ParseFailure.fromError(in))
        .map(q => q.copy(expr = ExprUtil.reduce(q.expr)))
    }

  def parseUnsafe(input: String): ItemQuery =
    parse(input).fold(m => sys.error(m.render), identity)
}
