{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.BasicSize exposing
    ( BasicSize(..)
    , all
    , asString
    , fromString
    , label
    )


type BasicSize
    = Small
    | Medium
    | Large


all : List BasicSize
all =
    [ Small
    , Medium
    , Large
    ]


fromString : String -> Maybe BasicSize
fromString str =
    case String.toLower str of
        "small" ->
            Just Small

        "medium" ->
            Just Medium

        "large" ->
            Just Large

        _ ->
            Nothing


asString : BasicSize -> String
asString size =
    label size |> String.toLower


label : BasicSize -> String
label size =
    case size of
        Small ->
            "Small"

        Medium ->
            "Medium"

        Large ->
            "Large"
