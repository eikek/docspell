{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.EventType exposing (..)

import Json.Decode as D
import Json.Encode as E


type EventType
    = TagsChanged
    | SetFieldValue
    | DeleteFieldValue
    | JobSubmitted
    | JobDone


all : List EventType
all =
    [ TagsChanged
    , SetFieldValue
    , DeleteFieldValue
    , JobSubmitted
    , JobDone
    ]


fromString : String -> Maybe EventType
fromString str =
    case String.toLower str of
        "tagschanged" ->
            Just TagsChanged

        "setfieldvalue" ->
            Just SetFieldValue

        "deletefieldvalue" ->
            Just DeleteFieldValue

        "jobsubmitted" ->
            Just JobSubmitted

        "jobdone" ->
            Just JobDone

        _ ->
            Nothing


asString : EventType -> String
asString et =
    case et of
        TagsChanged ->
            "TagsChanged"

        SetFieldValue ->
            "SetFieldValue"

        DeleteFieldValue ->
            "DeleteFieldValue"

        JobSubmitted ->
            "JobSubmitted"

        JobDone ->
            "JobDone"


decoder : D.Decoder EventType
decoder =
    let
        unwrap me =
            case me of
                Just et ->
                    D.succeed et

                Nothing ->
                    D.fail "Unknown event type!"
    in
    D.map fromString D.string
        |> D.andThen unwrap


encode : EventType -> E.Value
encode et =
    E.string (asString et)
