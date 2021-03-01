package docspell.query

import docspell.query.internal.ExprParser
import docspell.query.internal.ExprUtil

object ItemQueryParser {

  def parse(input: String): Either[ParseFailure, ItemQuery] =
    if (input.isEmpty) Right(ItemQuery.all)
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
