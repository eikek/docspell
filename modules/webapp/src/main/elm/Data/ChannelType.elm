{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ChannelType exposing
    ( ChannelType(..)
    , all
    , asString
    , decoder
    , encode
    , fromString
    , icon
    )

import Data.Icons as Icons
import Html exposing (Html, i)
import Html.Attributes exposing (class)
import Json.Decode as D
import Json.Encode as E


type ChannelType
    = Mail
    | Gotify
    | Matrix
    | Http


all : List ChannelType
all =
    [ Matrix
    , Gotify
    , Mail
    , Http
    ]


fromString : String -> Maybe ChannelType
fromString str =
    case String.toLower str of
        "mail" ->
            Just Mail

        "matrix" ->
            Just Matrix

        "gotify" ->
            Just Gotify

        "http" ->
            Just Http

        _ ->
            Nothing


asString : ChannelType -> String
asString et =
    case et of
        Mail ->
            "Mail"

        Matrix ->
            "Matrix"

        Gotify ->
            "Gotify"

        Http ->
            "Http"


decoder : D.Decoder ChannelType
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


encode : ChannelType -> E.Value
encode et =
    E.string (asString et)


icon : ChannelType -> String -> Html msg
icon ct classes =
    case ct of
        Matrix ->
            Icons.matrixIcon classes

        Mail ->
            i
                [ class "fa fa-envelope"
                , class classes
                ]
                []

        Gotify ->
            Icons.gotifyIcon classes

        Http ->
            i
                [ class "fa fa-ethernet"
                , class classes
                ]
                []
