{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.SearchMode exposing
    ( SearchMode(..)
    , asString
    , fromString
    )


type SearchMode
    = Normal
    | Trashed


fromString : String -> Maybe SearchMode
fromString str =
    case String.toLower str of
        "normal" ->
            Just Normal

        "trashed" ->
            Just Trashed

        _ ->
            Nothing


asString : SearchMode -> String
asString smode =
    case smode of
        Normal ->
            "normal"

        Trashed ->
            "trashed"
