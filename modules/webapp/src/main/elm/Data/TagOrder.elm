{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
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
