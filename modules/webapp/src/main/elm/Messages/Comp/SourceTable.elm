{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.SourceTable exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , abbrev : String
    , enabled : String
    , counter : String
    , priority : String
    , id : String
    , show : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , abbrev = "Abbrev"
    , enabled = "Enabled"
    , counter = "Counter"
    , priority = "Priority"
    , id = "Id"
    , show = "Show"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , abbrev = "Name"
    , enabled = "Aktiviert"
    , counter = "Zähler"
    , priority = "Priorität"
    , id = "ID"
    , show = "Anzeigen"
    }
