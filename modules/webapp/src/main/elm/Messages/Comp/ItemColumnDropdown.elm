{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemColumnDropdown exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics
import Messages.Data.ItemColumn


type alias Texts =
    { basics : Messages.Basics.Texts
    , column : Messages.Data.ItemColumn.Texts
    , placeholder : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , column = Messages.Data.ItemColumn.gb
    , placeholder = "Choose…"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , column = Messages.Data.ItemColumn.de
    , placeholder = "Wähle…"
    }
