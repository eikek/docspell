package docspell.query.js

import scala.scalajs.js
import scala.scalajs.js.annotation._

import docspell.query.ItemQueryParser

@JSExportTopLevel("DsItemQueryParser")
object JSItemQueryParser {

  @JSExport
  def parseToFailure(input: String): Failure =
    ItemQueryParser
      .parse(input)
      .swap
      .toOption
      .map(fr =>
        new Failure(
          fr.input,
          fr.failedAt,
          js.Array(fr.messages.toList.toSeq.map(_.render): _*)
        )
      )
      .orNull

  @JSExportAll
  case class Failure(input: String, failedAt: Int, messages: js.Array[String])

}
