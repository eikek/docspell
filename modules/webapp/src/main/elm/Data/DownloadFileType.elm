{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.DownloadFileType exposing (DownloadFileType(..), all, asString, fromString)


type DownloadFileType
    = Converted
    | Originals


all : List DownloadFileType
all =
    [ Converted, Originals ]


asString : DownloadFileType -> String
asString ft =
    case ft of
        Converted ->
            "converted"

        Originals ->
            "original"


fromString : String -> Maybe DownloadFileType
fromString str =
    case String.toLower str of
        "converted" ->
            Just Converted

        "originals" ->
            Just Originals

        _ ->
            Nothing
