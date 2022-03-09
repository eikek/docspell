{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationChannelTable exposing (..)

import Data.EventType exposing (EventType)
import Messages.Basics
import Messages.Data.EventType


type alias Texts =
    { basics : Messages.Basics.Texts
    , eventType : EventType -> Messages.Data.EventType.Texts
    , channelType : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , eventType = Messages.Data.EventType.gb
    , channelType = "Channel type"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , eventType = Messages.Data.EventType.de
    , channelType = "Kanaltyp"
    }

fr : Texts
fr =
    { basics = Messages.Basics.fr
    , eventType = Messages.Data.EventType.fr
    , channelType = "Type de canal"
    }
