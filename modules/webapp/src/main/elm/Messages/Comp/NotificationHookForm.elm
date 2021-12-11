{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHookForm exposing
    ( Texts
    , de
    , gb
    )

import Data.EventType exposing (EventType)
import Messages.Basics
import Messages.Comp.ChannelForm
import Messages.Comp.EventSample
import Messages.Data.ChannelType
import Messages.Data.EventType


type alias Texts =
    { basics : Messages.Basics.Texts
    , channelForm : Messages.Comp.ChannelForm.Texts
    , eventType : EventType -> Messages.Data.EventType.Texts
    , eventSample : Messages.Comp.EventSample.Texts
    , channelHeader : Messages.Data.ChannelType.Texts
    , enableDisable : String
    , eventsInfo : String
    , selectEvents : String
    , events : String
    , samplePayload : String
    , toggleAllEvents : String
    , eventFilter : String
    , eventFilterInfo : String
    , eventFilterClickForHelp : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , channelForm = Messages.Comp.ChannelForm.gb
    , eventType = Messages.Data.EventType.gb
    , eventSample = Messages.Comp.EventSample.gb
    , channelHeader = Messages.Data.ChannelType.gb
    , enableDisable = "Enabled / Disabled"
    , eventsInfo = "Select events that trigger this webhook"
    , selectEvents = "Select…"
    , events = "Events"
    , samplePayload = "Sample Payload"
    , toggleAllEvents = "Notify on all events"
    , eventFilter = "Event Filter Expression"
    , eventFilterInfo = "Optional specify an expression to filter events based on their JSON structure."
    , eventFilterClickForHelp = "Click here for help"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , channelForm = Messages.Comp.ChannelForm.de
    , eventType = Messages.Data.EventType.de
    , eventSample = Messages.Comp.EventSample.de
    , channelHeader = Messages.Data.ChannelType.de
    , enableDisable = "Aktiviert / Deaktivert"
    , eventsInfo = "Wähle die Ereignisse, die diesen webhook auslösen"
    , selectEvents = "Wähle…"
    , events = "Ereignisse"
    , samplePayload = "Beispieldaten"
    , toggleAllEvents = "Bei allen Ereignissen"
    , eventFilter = "Ereignisfilter"
    , eventFilterInfo = "Optionaler Ausdruck zum filtern von Ereignissen auf Basis ihrer JSON Struktur."
    , eventFilterClickForHelp = "Klicke für Hilfe"
    }
