module Messages.EquipmentFormComp exposing (..)

import Data.EquipmentUse exposing (EquipmentUse)
import Messages.EquipmentUseData


type alias Texts =
    { equipmentUseLabel : EquipmentUse -> String
    }


gb : Texts
gb =
    { equipmentUseLabel = Messages.EquipmentUseData.gb
    }
