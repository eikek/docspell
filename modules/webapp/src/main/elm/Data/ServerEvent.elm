{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ServerEvent exposing (ServerEvent(..), fromString)


type ServerEvent
    = ItemProcessed


fromString : String -> Maybe ServerEvent
fromString str =
    case String.toLower str of
        "item-processed" ->
            Just ItemProcessed

        _ ->
            Nothing
