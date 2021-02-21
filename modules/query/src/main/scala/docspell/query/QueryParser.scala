package docspell.query

import scala.scalajs.js.annotation._

@JSExportTopLevel("DsQueryParser")
object QueryParser {

  @JSExport
  def parse(input: String): Either[String, Query] = {
    Right(Query("parsed: " + input))

  }
}
