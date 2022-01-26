{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.AccountScope exposing (..)


type AccountScope
    = User
    | Collective


fold : a -> a -> AccountScope -> a
fold user coll scope =
    case scope of
        User ->
            user

        Collective ->
            coll


isUser : AccountScope -> Bool
isUser scope =
    fold True False scope


isCollective : AccountScope -> Bool
isCollective scope =
    fold False True scope
