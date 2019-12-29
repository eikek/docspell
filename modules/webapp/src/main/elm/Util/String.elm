module Util.String exposing
    ( crazyEncode
    , ellipsis
    , withDefault
    )

import Base64


crazyEncode : String -> String
crazyEncode str =
    let
        b64 =
            Base64.encode str

        len =
            String.length b64
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
        String.left (len - 3) str ++ "..."


withDefault : String -> String -> String
withDefault default str =
    if str == "" then
        default

    else
        str
