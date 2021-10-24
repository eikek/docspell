{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Pdf exposing (PdfMode(..), allModes, asString, detectUrl, fromString, serverUrl)

{-| Makes use of the fact, that docspell uses a `/view` suffix on the
path to provide a browser independent PDF view.
-}

import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)


type PdfMode
    = Detect
    | Native
    | Server


allModes : List PdfMode
allModes =
    [ Detect, Native, Server ]


asString : PdfMode -> String
asString mode =
    case mode of
        Detect ->
            "detect"

        Native ->
            "native"

        Server ->
            "server"


fromString : String -> Maybe PdfMode
fromString str =
    case String.toLower str of
        "detect" ->
            Just Detect

        "native" ->
            Just Native

        "server" ->
            Just Server

        _ ->
            Nothing


serverUrl : String -> String
serverUrl url =
    if String.endsWith "/" url then
        url ++ "view"

    else
        url ++ "/view"


detectUrl : Flags -> String -> String
detectUrl flags url =
    if flags.pdfSupported then
        url

    else
        serverUrl url
