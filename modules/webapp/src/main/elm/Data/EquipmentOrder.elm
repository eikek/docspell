{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.EquipmentOrder exposing (EquipmentOrder(..), asString)


type EquipmentOrder
    = NameAsc
    | NameDesc


asString : EquipmentOrder -> String
asString order =
    case order of
        NameAsc ->
            "name"

        NameDesc ->
            "-name"
