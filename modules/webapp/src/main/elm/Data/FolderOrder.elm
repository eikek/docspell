{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.FolderOrder exposing (FolderOrder(..), asString)


type FolderOrder
    = NameAsc
    | NameDesc
    | OwnerAsc
    | OwnerDesc


asString : FolderOrder -> String
asString order =
    case order of
        NameAsc ->
            "name"

        NameDesc ->
            "-name"

        OwnerAsc ->
            "owner"

        OwnerDesc ->
            "-owner"
