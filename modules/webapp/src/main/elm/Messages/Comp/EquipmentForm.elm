module Messages.Comp.EquipmentForm exposing (..)

import Data.EquipmentUse exposing (EquipmentUse)
import Messages.Data.EquipmentUse


type alias Texts =
    { equipmentUseLabel : EquipmentUse -> String
    }


gb : Texts
gb =
    { equipmentUseLabel = Messages.Data.EquipmentUse.gb
    }
