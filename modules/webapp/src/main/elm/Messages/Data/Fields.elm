module Messages.Data.Fields exposing (gb)

import Data.Fields exposing (Field(..))


gb : Field -> String
gb field =
    case field of
        Tag ->
            "Tag"

        Folder ->
            "Folder"

        CorrOrg ->
            "Correspondent Organization"

        CorrPerson ->
            "Correspondent Person"

        ConcPerson ->
            "Concerning Person"

        ConcEquip ->
            "Concerned Equipment"

        Date ->
            "Date"

        DueDate ->
            "Due Date"

        Direction ->
            "Direction"

        PreviewImage ->
            "Preview Image"

        CustomFields ->
            "Custom Fields"

        SourceName ->
            "Item Source"
