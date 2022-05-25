package docspell.website

import docspell.addons.out._
import docspell.common.bc._
import io.circe.syntax._

object AddonOutputMiniExample extends Helper {

  val example = AddonOutput(
    commands = List(
      BackendCommand.ItemUpdate(
        itemId = id("XabZ-item-id"),
        actions = List(
          ItemAction.AddTags(Set("tag1", "tag2"))
        )
      )
    )
  )

  def exampleJson =
    example.asJson.spaces2

}
