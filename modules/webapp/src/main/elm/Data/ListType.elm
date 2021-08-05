{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.ListType exposing
    ( ListType(..)
    , all
    , fromString
    , label
    , toString
    )


type ListType
    = Blacklist
    | Whitelist


all : List ListType
all =
    [ Blacklist, Whitelist ]


toString : ListType -> String
toString lt =
    case lt of
        Blacklist ->
            "blacklist"

        Whitelist ->
            "whitelist"


label : ListType -> String
label lt =
    case lt of
        Blacklist ->
            "Blacklist"

        Whitelist ->
            "Whitelist"


fromString : String -> Maybe ListType
fromString str =
    case String.toLower str of
        "blacklist" ->
            Just Blacklist

        "whitelist" ->
            Just Whitelist

        _ ->
            Nothing
