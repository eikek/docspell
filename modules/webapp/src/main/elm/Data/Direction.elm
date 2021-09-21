{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Direction exposing
    ( Direction(..)
    , all
    , asString
    , fromString
    , icon
    , icon2
    , iconFromMaybe
    , iconFromMaybe2
    , iconFromString
    , iconFromString2
    )


type Direction
    = Incoming
    | Outgoing


fromString : String -> Maybe Direction
fromString str =
    case String.toLower str of
        "outgoing" ->
            Just Outgoing

        "incoming" ->
            Just Incoming

        _ ->
            Nothing


all : List Direction
all =
    [ Incoming
    , Outgoing
    ]


asString : Direction -> String
asString dir =
    case dir of
        Incoming ->
            "Incoming"

        Outgoing ->
            "Outgoing"


icon : Direction -> String
icon dir =
    case dir of
        Incoming ->
            "level down alternate icon"

        Outgoing ->
            "level up alternate icon"


icon2 : Direction -> String
icon2 dir =
    case dir of
        Incoming ->
            "fa fa-level-down-alt"

        Outgoing ->
            "fa fa-level-up-alt"


unknownIcon : String
unknownIcon =
    "question circle outline icon"


unknownIcon2 : String
unknownIcon2 =
    "fa fa-question-circle font-thin"


iconFromString : String -> String
iconFromString dir =
    fromString dir
        |> Maybe.map icon
        |> Maybe.withDefault unknownIcon


iconFromString2 : String -> String
iconFromString2 dir =
    fromString dir
        |> Maybe.map icon2
        |> Maybe.withDefault unknownIcon2


iconFromMaybe : Maybe String -> String
iconFromMaybe ms =
    Maybe.map iconFromString ms
        |> Maybe.withDefault unknownIcon


iconFromMaybe2 : Maybe String -> String
iconFromMaybe2 ms =
    Maybe.map iconFromString2 ms
        |> Maybe.withDefault unknownIcon2
