{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHookForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.EventType exposing (EventType)
import Messages.Basics
import Messages.Comp.ChannelRefInput
import Messages.Comp.EventSample
import Messages.Data.EventType


type alias Texts =
    { basics : Messages.Basics.Texts
    , channelRef : Messages.Comp.ChannelRefInput.Texts
    , eventType : EventType -> Messages.Data.EventType.Texts
    , eventSample : Messages.Comp.EventSample.Texts
    , channelHeader : String
    , enableDisable : String
    , eventsInfo : String
    , selectEvents : String
    , events : String
    , samplePayload : String
    , toggleAllEvents : String
    , eventFilter : String
    , eventFilterInfo : String
    , eventFilterClickForHelp : String
    , jsonPayload : String
    , messagePayload : String
    , payloadInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , channelRef = Messages.Comp.ChannelRefInput.gb
    , eventType = Messages.Data.EventType.gb
    , eventSample = Messages.Comp.EventSample.gb
    , channelHeader = "Select channels"
    , enableDisable = "Enabled / Disabled"
    , eventsInfo = "Select events that trigger this webhook"
    , selectEvents = "Select…"
    , events = "Events"
    , samplePayload = "Sample Payload"
    , toggleAllEvents = "Notify on all events"
    , eventFilter = "Event Filter Expression"
    , eventFilterInfo = "Optional specify an expression to filter events based on their JSON structure."
    , eventFilterClickForHelp = "Click here for help"
    , jsonPayload = "JSON"
    , messagePayload = "Message"
    , payloadInfo = "Message payloads are sent to gotify, email and matrix. The JSON is sent to http channel."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , channelRef = Messages.Comp.ChannelRefInput.de
    , eventType = Messages.Data.EventType.de
    , eventSample = Messages.Comp.EventSample.de
    , channelHeader = "Kanäle"
    , enableDisable = "Aktiviert / Deaktivert"
    , eventsInfo = "Wähle die Ereignisse, die diesen webhook auslösen"
    , selectEvents = "Wähle…"
    , events = "Ereignisse"
    , samplePayload = "Beispieldaten"
    , toggleAllEvents = "Bei allen Ereignissen"
    , eventFilter = "Ereignisfilter"
    , eventFilterInfo = "Optionaler Ausdruck zum filtern von Ereignissen auf Basis ihrer JSON Struktur."
    , eventFilterClickForHelp = "Klicke für Hilfe"
    , jsonPayload = "JSON"
    , messagePayload = "Nachricht"
    , payloadInfo = "Es werden abhängig vom Kanal JSON oder Nachricht-Formate versendet. Der HTTP Kanal empfängt nur JSON, an die anderen wird das Nachrichtformat gesendet."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , channelRef = Messages.Comp.ChannelRefInput.fr
    , eventType = Messages.Data.EventType.fr
    , eventSample = Messages.Comp.EventSample.fr
    , channelHeader = "Sélectionner les canaux"
    , enableDisable = "Activé / Désactivé"
    , eventsInfo = "Sélectionner un événement que déclenche ce webhook"
    , selectEvents = "Sélectionner..."
    , events = "Événements"
    , samplePayload = "Aperçu du contenu envoyé"
    , toggleAllEvents = "Notifier pour les événements"
    , eventFilter = "Expression de filtre des événements"
    , eventFilterInfo = "Spécifier (optionnel) une expression pour filtrer les événements selon leur structure JSON"
    , eventFilterClickForHelp = "Cliquer pour l'aide"
    , jsonPayload = "JSON"
    , messagePayload = "Message"
    , payloadInfo = "Les messages sont envoyés à gotify, email and matrix. Le JSON est envoyé au canal HTTP."
    }
