{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BookmarkTable exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , user : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , user = "User"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , user = "Benutzer"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , user = "Utilisateur"
    }
