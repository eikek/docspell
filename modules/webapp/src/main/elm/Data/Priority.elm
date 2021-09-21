{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Priority exposing
    ( Priority(..)
    , all
    , fromString
    , next
    , toName
    )


type Priority
    = High
    | Low


fromString : String -> Maybe Priority
fromString str =
    let
        s =
            String.toLower str
    in
    case s of
        "low" ->
            Just Low

        "high" ->
            Just High

        _ ->
            Nothing


toName : Priority -> String
toName lang =
    case lang of
        Low ->
            "Low"

        High ->
            "High"


next : Priority -> Priority
next prio =
    case prio of
        High ->
            Low

        Low ->
            High


all : List Priority
all =
    [ Low, High ]
