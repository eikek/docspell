package docspell.query

import scala.scalajs.js.annotation._

import docspell.query.internal.ExprParser

@JSExportTopLevel("DsItemQueryParser")
object ItemQueryParser {

  @JSExport
  def parse(input: String): Either[String, ItemQuery] =
    ExprParser.exprParser
      .parseAll(input.trim)
      .left
      .map(pe => s"Error parsing: '${input.trim}': $pe")
      .map(expr => ItemQuery(expr, Some(input.trim)))

  def parseUnsafe(input: String): ItemQuery =
    parse(input).fold(sys.error, identity)
}
