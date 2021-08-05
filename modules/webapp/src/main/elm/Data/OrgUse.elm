{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.OrgUse exposing
    ( OrgUse(..)
    , all
    , asString
    , fromString
    )


type OrgUse
    = Correspondent
    | Disabled


fromString : String -> Maybe OrgUse
fromString str =
    case String.toLower str of
        "correspondent" ->
            Just Correspondent

        "disabled" ->
            Just Disabled

        _ ->
            Nothing


asString : OrgUse -> String
asString pu =
    case pu of
        Correspondent ->
            "correspondent"

        Disabled ->
            "disabled"


all : List OrgUse
all =
    [ Correspondent, Disabled ]
