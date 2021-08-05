{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Data.EquipmentUse exposing
    ( de
    , gb
    )

import Data.EquipmentUse exposing (EquipmentUse(..))


gb : EquipmentUse -> String
gb pu =
    case pu of
        Concerning ->
            "Concerning"

        Disabled ->
            "Disabled"


de : EquipmentUse -> String
de pu =
    case pu of
        Concerning ->
            "Betreffend"

        Disabled ->
            "Deaktiviert"
