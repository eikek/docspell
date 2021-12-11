{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHookTable exposing
    ( Texts
    , de
    , gb
    )

import Data.EventType exposing (EventType)
import Messages.Basics
import Messages.Data.EventType


type alias Texts =
    { basics : Messages.Basics.Texts
    , eventType : EventType -> Messages.Data.EventType.Texts
    , enabled : String
    , channel : String
    , events : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , eventType = Messages.Data.EventType.gb
    , enabled = "Enabled"
    , channel = "Channel"
    , events = "Events"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , eventType = Messages.Data.EventType.de
    , enabled = "Aktiv"
    , channel = "Kanal"
    , events = "Ereignisse"
    }
