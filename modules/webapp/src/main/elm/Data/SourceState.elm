{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Data.SourceState exposing
    ( SourceState(..)
    , all
    , fromString
    , toString
    )


type SourceState
    = Active
    | Disabled


fromString : String -> Maybe SourceState
fromString str =
    case String.toLower str of
        "active" ->
            Just Active

        "disabled" ->
            Just Disabled

        _ ->
            Nothing


all : List SourceState
all =
    [ Active
    , Disabled
    ]


toString : SourceState -> String
toString dir =
    case dir of
        Active ->
            "Active"

        Disabled ->
            "Disabled"
