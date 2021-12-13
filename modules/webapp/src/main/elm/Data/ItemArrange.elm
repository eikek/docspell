{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ItemArrange exposing (ItemArrange(..), asString, fromString)


type ItemArrange
    = Cards
    | List


asString : ItemArrange -> String
asString arr =
    case arr of
        Cards ->
            "cards"

        List ->
            "list"


fromString : String -> Maybe ItemArrange
fromString str =
    case String.toLower str of
        "cards" ->
            Just Cards

        "list" ->
            Just List

        _ ->
            Nothing
