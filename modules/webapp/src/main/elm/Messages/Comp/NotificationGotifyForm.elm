{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationGotifyForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , gotifyUrl : String
    , appKey : String
    , priority : String
    , priorityInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , gotifyUrl = "Gotify URL"
    , appKey = "App Key"
    , priority = "Priority"
    , priorityInfo = "A number denoting the importance of a message controlling notification behaviour. The higher the more important."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , gotifyUrl = "Gotify URL"
    , appKey = "App Key"
    , priority = "Priorität"
    , priorityInfo = "Eine Zahl, um die Wichtigkeit anzugeben (je höher desto wichtiger). Es steuert, wie eine Notifizierung erscheint."
    }
