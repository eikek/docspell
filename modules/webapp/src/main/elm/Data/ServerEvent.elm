{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ServerEvent exposing (ServerEvent(..), decode)

import Json.Decode as D


type ServerEvent
    = ItemProcessed
    | JobsWaiting Int


decoder : D.Decoder ServerEvent
decoder =
    D.field "tag" D.string
        |> D.andThen decodeTag


decode : D.Value -> Result String ServerEvent
decode json =
    D.decodeValue decoder json
        |> Result.mapError D.errorToString


decodeTag : String -> D.Decoder ServerEvent
decodeTag tag =
    case tag of
        "item-processed" ->
            D.succeed ItemProcessed

        "jobs-waiting" ->
            D.field "content" D.int
                |> D.map JobsWaiting

        _ ->
            D.fail ("Unknown tag: " ++ tag)
