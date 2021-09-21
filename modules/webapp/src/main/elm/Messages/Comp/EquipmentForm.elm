{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.EquipmentForm exposing
    ( Texts
    , de
    , gb
    )

import Data.EquipmentUse exposing (EquipmentUse)
import Messages.Basics
import Messages.Data.EquipmentUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , use : String
    , useAsConcerning : String
    , useNotSuggestions : String
    , equipmentUseLabel : EquipmentUse -> String
    , notes : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , use = "Use"
    , useAsConcerning = "Use as concerning equipment"
    , useNotSuggestions = "Do not use for suggestions."
    , equipmentUseLabel = Messages.Data.EquipmentUse.gb
    , notes = "Notes"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , use = "Art"
    , useAsConcerning = "Als betreffende Ausstattung verwenden"
    , useNotSuggestions = "Nicht für Vorschläge verwenden"
    , equipmentUseLabel = Messages.Data.EquipmentUse.de
    , notes = "Notizen"
    }
