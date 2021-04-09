module Messages.Data.EquipmentUse exposing (..)

import Data.EquipmentUse exposing (EquipmentUse(..))


gb : EquipmentUse -> String
gb pu =
    case pu of
        Concerning ->
            "Concerning"

        Disabled ->
            "Disabled"
