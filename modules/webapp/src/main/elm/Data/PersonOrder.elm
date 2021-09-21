{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.PersonOrder exposing (PersonOrder(..), asString)


type PersonOrder
    = NameAsc
    | NameDesc
    | OrgAsc
    | OrgDesc


asString : PersonOrder -> String
asString order =
    case order of
        NameAsc ->
            "name"

        NameDesc ->
            "-name"

        OrgAsc ->
            "org"

        OrgDesc ->
            "-org"
