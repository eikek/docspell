{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
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
