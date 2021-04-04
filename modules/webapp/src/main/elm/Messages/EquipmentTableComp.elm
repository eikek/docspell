module Messages.EquipmentTableComp exposing (..)

import Data.EquipmentUse exposing (EquipmentUse)
import Messages.EquipmentUseData


type alias Texts =
    { name : String
    , use : String
    , equipmentUseLabel : EquipmentUse -> String
    }


gb : Texts
gb =
    { name = "Name"
    , use = "Use"
    , equipmentUseLabel = Messages.EquipmentUseData.gb
    }
