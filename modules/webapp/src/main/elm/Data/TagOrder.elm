{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.TagOrder exposing (TagOrder(..), asString)


type TagOrder
    = NameAsc
    | NameDesc
    | CategoryAsc
    | CategoryDesc


asString : TagOrder -> String
asString order =
    case order of
        NameAsc ->
            "name"

        NameDesc ->
            "-name"

        CategoryAsc ->
            "category"

        CategoryDesc ->
            "-category"
