{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.OrganizationOrder exposing (OrganizationOrder(..), asString)


type OrganizationOrder
    = NameAsc
    | NameDesc


asString : OrganizationOrder -> String
asString order =
    case order of
        NameAsc ->
            "name"

        NameDesc ->
            "-name"
