module Messages.Data.Fields exposing
    ( de
    , gb
    )

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


de : Field -> String
de field =
    case field of
        Tag ->
            "Tag"

        Folder ->
            "Ordner"

        CorrOrg ->
            "Korrespondent Organisation"

        CorrPerson ->
            "Korrespondent Person"

        ConcPerson ->
            "Betreffend Person"

        ConcEquip ->
            "Betreffend Zubehör"

        Date ->
            "Datum"

        DueDate ->
            "Fälligkeits-Datum"

        Direction ->
            "Richtung"

        PreviewImage ->
            "Vorschau Bild"

        CustomFields ->
            "Benutzer Felder"

        SourceName ->
            "Quelle"
