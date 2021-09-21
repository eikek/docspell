{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ItemSelection exposing
    ( ItemSelection(..)
    , isActive
    , isSelected
    )

import Set exposing (Set)


type ItemSelection
    = Inactive
    | Active (Set String)


isSelected : String -> ItemSelection -> Bool
isSelected id set =
    case set of
        Inactive ->
            False

        Active ids ->
            Set.member id ids


isActive : ItemSelection -> Bool
isActive sel =
    case sel of
        Active _ ->
            True

        Inactive ->
            False
