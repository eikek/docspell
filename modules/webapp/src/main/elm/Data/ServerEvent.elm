{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ServerEvent exposing (AddonInfo, ServerEvent(..), decode)

import Json.Decode as D
import Json.Decode.Pipeline as P


type ServerEvent
    = JobSubmitted String
    | JobDone String
    | JobsWaiting Int
    | AddonInstalled AddonInfo


type alias AddonInfo =
    { success : Bool
    , addonId : Maybe String
    , addonUrl : Maybe String
    , message : String
    }


addonInfoDecoder : D.Decoder AddonInfo
addonInfoDecoder =
    D.succeed AddonInfo
        |> P.required "success" D.bool
        |> P.optional "addonId" (D.maybe D.string) Nothing
        |> P.optional "addonUrl" (D.maybe D.string) Nothing
        |> P.required "message" D.string


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
        "job-done" ->
            D.field "content" D.string
                |> D.map JobDone

        "job-submitted" ->
            D.field "content" D.string
                |> D.map JobSubmitted

        "jobs-waiting" ->
            D.field "content" D.int
                |> D.map JobsWaiting

        "addon-installed" ->
            D.field "content" addonInfoDecoder
                |> D.map AddonInstalled

        _ ->
            D.fail ("Unknown tag: " ++ tag)
