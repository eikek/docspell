{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.CustomFieldOrder exposing (CustomFieldOrder(..), asString)


type CustomFieldOrder
    = LabelAsc
    | LabelDesc
    | FormatAsc
    | FormatDesc


asString : CustomFieldOrder -> String
asString order =
    case order of
        LabelAsc ->
            "label"

        LabelDesc ->
            "-label"

        FormatAsc ->
            "type"

        FormatDesc ->
            "-type"
