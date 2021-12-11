{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.NotificationHook exposing (NotificationHook, decoder, empty, encode)

import Data.ChannelType exposing (ChannelType)
import Data.EventType exposing (EventType)
import Data.NotificationChannel exposing (NotificationChannel)
import Json.Decode as D
import Json.Encode as E


type alias NotificationHook =
    { id : String
    , enabled : Bool
    , channel : NotificationChannel
    , allEvents : Bool
    , eventFilter : Maybe String
    , events : List EventType
    }


empty : ChannelType -> NotificationHook
empty ct =
    { id = ""
    , enabled = True
    , channel = Data.NotificationChannel.empty ct
    , allEvents = False
    , eventFilter = Nothing
    , events = []
    }


decoder : D.Decoder NotificationHook
decoder =
    D.map6 NotificationHook
        (D.field "id" D.string)
        (D.field "enabled" D.bool)
        (D.field "channel" Data.NotificationChannel.decoder)
        (D.field "allEvents" D.bool)
        (D.field "eventFilter" (D.maybe D.string))
        (D.field "events" (D.list Data.EventType.decoder))


encode : NotificationHook -> E.Value
encode hook =
    E.object
        [ ( "id", E.string hook.id )
        , ( "enabled", E.bool hook.enabled )
        , ( "channel", Data.NotificationChannel.encode hook.channel )
        , ( "allEvents", E.bool hook.allEvents )
        , ( "eventFilter", Maybe.map E.string hook.eventFilter |> Maybe.withDefault E.null )
        , ( "events", E.list Data.EventType.encode hook.events )
        ]



--- private
