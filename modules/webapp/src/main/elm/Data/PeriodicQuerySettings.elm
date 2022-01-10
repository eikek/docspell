{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.PeriodicQuerySettings exposing (PeriodicQuerySettings, decoder, empty, encode)

import Data.ChannelType exposing (ChannelType)
import Data.NotificationChannel exposing (NotificationChannel)
import Json.Decode as D
import Json.Encode as E


type alias PeriodicQuerySettings =
    { id : String
    , enabled : Bool
    , summary : Maybe String
    , channel : NotificationChannel
    , query : Maybe String
    , bookmark : Maybe String
    , schedule : String
    }


empty : ChannelType -> PeriodicQuerySettings
empty ct =
    { id = ""
    , enabled = False
    , summary = Nothing
    , channel = Data.NotificationChannel.empty ct
    , query = Nothing
    , bookmark = Nothing
    , schedule = ""
    }


decoder : D.Decoder PeriodicQuerySettings
decoder =
    D.map7 PeriodicQuerySettings
        (D.field "id" D.string)
        (D.field "enabled" D.bool)
        (D.maybe (D.field "summary" D.string))
        (D.field "channel" Data.NotificationChannel.decoder)
        (D.maybe (D.field "query" D.string))
        (D.maybe (D.field "bookmark" D.string))
        (D.field "schedule" D.string)


encode : PeriodicQuerySettings -> E.Value
encode s =
    E.object
        [ ( "id", E.string s.id )
        , ( "enabled", E.bool s.enabled )
        , ( "summary", Maybe.map E.string s.summary |> Maybe.withDefault E.null )
        , ( "channel", Data.NotificationChannel.encode s.channel )
        , ( "query", Maybe.map E.string s.query |> Maybe.withDefault E.null )
        , ( "bookmark", Maybe.map E.string s.bookmark |> Maybe.withDefault E.null )
        , ( "schedule", E.string s.schedule )
        ]
