module Data.EquipmentUse exposing
    ( EquipmentUse(..)
    , all
    , asString
    , fromString
    , label
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


label : EquipmentUse -> String
label pu =
    case pu of
        Concerning ->
            "Concerning"

        Disabled ->
            "Disabled"


all : List EquipmentUse
all =
    [ Concerning, Disabled ]
