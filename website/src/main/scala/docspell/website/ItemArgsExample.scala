package docspell.website

import cats.syntax.option._
import docspell.common.{Language, ProcessItemArgs}
import io.circe.syntax._

object ItemArgsExample extends Helper {

  val example = ProcessItemArgs.ProcessMeta(
    collective = cid,
    itemId = None,
    language = Language.English,
    direction = None,
    sourceAbbrev = "scanner",
    folderId = None,
    validFileTypes = Seq.empty,
    skipDuplicate = true,
    fileFilter = None,
    tags = List("given-tag-1").some,
    reprocess = false,
    attachmentsOnly = None
  )

  val exampleJson = example.asJson.spaces2
}
