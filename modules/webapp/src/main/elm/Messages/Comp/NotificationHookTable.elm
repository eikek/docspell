{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHookTable exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Data.EventType exposing (EventType)
import Messages.Basics
import Messages.Data.ChannelType
import Messages.Data.EventType


type alias Texts =
    { basics : Messages.Basics.Texts
    , eventType : EventType -> Messages.Data.EventType.Texts
    , channelType : Messages.Data.ChannelType.Texts
    , enabled : String
    , channel : String
    , events : String
    , allEvents : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , eventType = Messages.Data.EventType.gb
    , channelType = Messages.Data.ChannelType.gb
    , enabled = "Enabled"
    , channel = "Channel"
    , events = "Events"
    , allEvents = "All"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , eventType = Messages.Data.EventType.de
    , channelType = Messages.Data.ChannelType.de
    , enabled = "Aktiv"
    , channel = "Kanal"
    , events = "Ereignisse"
    , allEvents = "Alle"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , eventType = Messages.Data.EventType.fr
    , channelType = Messages.Data.ChannelType.fr
    , enabled = "Activé"
    , channel = "Canal"
    , events = "Événements"
    , allEvents = "Tout"
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , eventType = Messages.Data.EventType.ja
    , channelType = Messages.Data.ChannelType.ja
    , enabled = "有効"
    , channel = "チャネル"
    , events = "イベント"
    , allEvents = "すべて"
    }
