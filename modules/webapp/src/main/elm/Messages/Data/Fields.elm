{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

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
            "Korrespondierende Organisation"

        CorrPerson ->
            "Korrespondierende Person"

        ConcPerson ->
            "Betreffende Person"

        ConcEquip ->
            "Betreffende Ausstattung"

        Date ->
            "Datum"

        DueDate ->
            "Fälligkeitsdatum"

        Direction ->
            "Richtung"

        PreviewImage ->
            "Vorschaubild"

        CustomFields ->
            "Benutzerfelder"

        SourceName ->
            "Quelle"
