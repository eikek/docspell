module Messages.Comp.EquipmentTable exposing (Texts, gb)

import Data.EquipmentUse exposing (EquipmentUse)
import Messages.Basics
import Messages.Data.EquipmentUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , use : String
    , equipmentUseLabel : EquipmentUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , use = "Use"
    , equipmentUseLabel = Messages.Data.EquipmentUse.gb
    }
