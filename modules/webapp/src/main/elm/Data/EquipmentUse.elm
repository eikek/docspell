{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.EquipmentUse exposing
    ( EquipmentUse(..)
    , all
    , asString
    , fromString
    )

import Api.Model.Equipment exposing (Equipment)


type EquipmentUse
    = Concerning
    | Disabled


fromString : String -> Maybe EquipmentUse
fromString str =
    case String.toLower str of
        "concerning" ->
            Just Concerning

        "disabled" ->
            Just Disabled

        _ ->
            Nothing


asString : EquipmentUse -> String
asString pu =
    case pu of
        Concerning ->
            "concerning"

        Disabled ->
            "disabled"


all : List EquipmentUse
all =
    [ Concerning, Disabled ]
