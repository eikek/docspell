{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.PeriodicDueItemsSettings exposing (..)

import Api.Model.Tag exposing (Tag)
import Data.ChannelType exposing (ChannelType)
import Data.NotificationChannel exposing (NotificationChannel)
import Json.Decode as Decode
import Json.Decode.Pipeline as P
import Json.Encode as Encode



{--
  - Settings for notifying about due items.
 --}


type alias PeriodicDueItemsSettings =
    { id : String
    , enabled : Bool
    , summary : Maybe String
    , channel : NotificationChannel
    , schedule : String
    , remindDays : Int
    , capOverdue : Bool
    , tagsInclude : List Tag
    , tagsExclude : List Tag
    }


empty : ChannelType -> PeriodicDueItemsSettings
empty ct =
    { id = ""
    , enabled = False
    , summary = Nothing
    , channel = Data.NotificationChannel.empty ct
    , schedule = ""
    , remindDays = 0
    , capOverdue = False
    , tagsInclude = []
    , tagsExclude = []
    }


decoder : Decode.Decoder PeriodicDueItemsSettings
decoder =
    Decode.succeed PeriodicDueItemsSettings
        |> P.required "id" Decode.string
        |> P.required "enabled" Decode.bool
        |> P.optional "summary" (Decode.maybe Decode.string) Nothing
        |> P.required "channel" Data.NotificationChannel.decoder
        |> P.required "schedule" Decode.string
        |> P.required "remindDays" Decode.int
        |> P.required "capOverdue" Decode.bool
        |> P.required "tagsInclude" (Decode.list Api.Model.Tag.decoder)
        |> P.required "tagsExclude" (Decode.list Api.Model.Tag.decoder)


encode : PeriodicDueItemsSettings -> Encode.Value
encode value =
    Encode.object
        [ ( "id", Encode.string value.id )
        , ( "enabled", Encode.bool value.enabled )
        , ( "summary", (Maybe.map Encode.string >> Maybe.withDefault Encode.null) value.summary )
        , ( "channel", Data.NotificationChannel.encode value.channel )
        , ( "schedule", Encode.string value.schedule )
        , ( "remindDays", Encode.int value.remindDays )
        , ( "capOverdue", Encode.bool value.capOverdue )
        , ( "tagsInclude", Encode.list Api.Model.Tag.encode value.tagsInclude )
        , ( "tagsExclude", Encode.list Api.Model.Tag.encode value.tagsExclude )
        ]
