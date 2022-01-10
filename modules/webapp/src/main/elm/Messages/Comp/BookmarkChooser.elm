{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkChooser exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , userLabel : String
    , collectiveLabel : String
    , shareLabel : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , userLabel = "Personal"
    , collectiveLabel = "Collective"
    , shareLabel = "Shares"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , userLabel = "Persönlich"
    , collectiveLabel = "Kollektiv"
    , shareLabel = "Freigaben"
    }
