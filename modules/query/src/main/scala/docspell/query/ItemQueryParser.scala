package docspell.query

import scala.scalajs.js.annotation._

import docspell.query.internal.ExprParser
import docspell.query.internal.ExprUtil

@JSExportTopLevel("DsItemQueryParser")
object ItemQueryParser {

  @JSExport
  def parse(input: String): Either[String, ItemQuery] =
    if (input.isEmpty) Right(ItemQuery.all)
    else {
      val in = if (input.charAt(0) == '(') input else s"(& $input )"
      ExprParser
        .parseQuery(in)
        .left
        .map(pe => s"Error parsing: '$input': $pe") //TODO
        .map(q => q.copy(expr = ExprUtil.reduce(q.expr)))
    }

  def parseUnsafe(input: String): ItemQuery =
    parse(input).fold(sys.error, identity)
}
