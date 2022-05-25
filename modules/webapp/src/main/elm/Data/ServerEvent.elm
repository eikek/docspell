{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ServerEvent exposing (AddonInfo, JobDoneDetails, ServerEvent(..), decode, isAddonExistingItem)

import Json.Decode as D
import Json.Decode.Pipeline as P


type ServerEvent
    = JobSubmitted String
    | JobDone JobDoneDetails
    | JobsWaiting Int
    | AddonInstalled AddonInfo


type alias AddonInfo =
    { success : Bool
    , addonId : Maybe String
    , addonUrl : Maybe String
    , message : String
    }


type alias JobDoneDetails =
    { task : String
    , args : Maybe D.Value
    , result : Maybe D.Value
    }


{-| Return wether the job done details belong to running an addon of
that item with the given id.
-}
isAddonExistingItem : String -> JobDoneDetails -> Bool
isAddonExistingItem itemId details =
    let
        itemIdDecoder =
            D.field "itemId" D.string

        -- This decodes the structure from scalas ItemAddonTaskArgs (only itemId)
        decodedId =
            Maybe.map (D.decodeValue itemIdDecoder) details.args
                |> Maybe.andThen Result.toMaybe
    in
    details.task
        == "addon-existing-item"
        && (itemId /= "" && decodedId == Just itemId)


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
            D.field "content" (D.map JobDone decodeJobDoneDetails)

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


decodeJobDoneDetails : D.Decoder JobDoneDetails
decodeJobDoneDetails =
    D.map3 JobDoneDetails
        (D.field "task" D.string)
        (D.field "args" (D.maybe D.value))
        (D.field "result" (D.maybe D.value))
