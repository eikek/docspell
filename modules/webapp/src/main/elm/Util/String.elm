{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.String exposing
    ( appendIfAbsent
    , crazyEncode
    , ellipsis
    , firstSentenceOrMax
    , isBlank
    , isNothingOrBlank
    , underscoreToSpace
    , withDefault
    )

import Base64


crazyEncode : String -> String
crazyEncode str =
    let
        b64 =
            Base64.encode str
    in
    case String.right 2 b64 |> String.toList of
        '=' :: '=' :: [] ->
            String.dropRight 2 b64 ++ "0"

        _ :: '=' :: [] ->
            String.dropRight 1 b64 ++ "1"

        _ ->
            b64


ellipsis : Int -> String -> String
ellipsis len str =
    if String.length str <= len then
        str

    else
        String.left (len - 1) str ++ "…"


firstSentenceOrMax : Int -> String -> Maybe String
firstSentenceOrMax maxLen str =
    let
        idx =
            String.indexes "." str
                |> List.head
                |> Maybe.map ((+) 2)
                |> Maybe.map (min maxLen)
                |> Maybe.withDefault maxLen

        len =
            String.length str
    in
    if len <= maxLen then
        Nothing

    else
        Just <| String.left (idx - 1) str ++ "…"


withDefault : String -> String -> String
withDefault default str =
    if str == "" then
        default

    else
        str


underscoreToSpace : String -> String
underscoreToSpace str =
    String.replace "_" " " str


isBlank : String -> Bool
isBlank s =
    s == "" || (String.trim s == "")


isNothingOrBlank : Maybe String -> Bool
isNothingOrBlank ms =
    Maybe.map isBlank ms
        |> Maybe.withDefault True


appendIfAbsent : String -> String -> String
appendIfAbsent suffix str =
    if String.endsWith suffix str then
        str

    else
        str ++ suffix
