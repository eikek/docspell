{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.EquipmentTable exposing
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
    , equipmentUseLabel : EquipmentUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , use = "Use"
    , equipmentUseLabel = Messages.Data.EquipmentUse.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , use = "Art"
    , equipmentUseLabel = Messages.Data.EquipmentUse.de
    }
