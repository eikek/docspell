module Messages.Comp.EquipmentTable exposing (..)

import Data.EquipmentUse exposing (EquipmentUse)
import Messages.Data.EquipmentUse


type alias Texts =
    { name : String
    , use : String
    , equipmentUseLabel : EquipmentUse -> String
    }


gb : Texts
gb =
    { name = "Name"
    , use = "Use"
    , equipmentUseLabel = Messages.Data.EquipmentUse.gb
    }
