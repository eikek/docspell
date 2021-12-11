{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHttpForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpUrl : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpUrl = "Http URL"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpUrl = "URL"
    }
