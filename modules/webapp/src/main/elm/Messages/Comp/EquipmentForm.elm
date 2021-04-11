module Messages.Comp.EquipmentForm exposing (Texts, gb)

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
