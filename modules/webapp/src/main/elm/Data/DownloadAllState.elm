{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.DownloadAllState exposing (DownloadAllState(..), all, asString, fromString)


type DownloadAllState
    = NotPresent
    | Forbidden
    | Empty
    | Preparing
    | Present


all : List DownloadAllState
all =
    [ NotPresent, Forbidden, Empty, Preparing, Present ]


asString : DownloadAllState -> String
asString st =
    case st of
        NotPresent ->
            "notpresent"

        Forbidden ->
            "forbidden"

        Empty ->
            "empty"

        Preparing ->
            "preparing"

        Present ->
            "present"


fromString : String -> Maybe DownloadAllState
fromString str =
    let
        name =
            String.toLower str
    in
    List.filter (\e -> asString e == name) all |> List.head
