module Util.Duration exposing (Duration, toHuman)

-- 486ms -> 12s -> 1:05 -> 59:45 -> 1:02:12


type alias Duration =
    Int


toHuman : Duration -> String
toHuman dur =
    fromMillis dur



-- implementation


fromMillis : Int -> String
fromMillis ms =
    case ms // 1000 of
        0 ->
            String.fromInt ms ++ "ms"

        n ->
            fromSeconds n


fromSeconds : Int -> String
fromSeconds sec =
    case sec // 60 of
        0 ->
            String.fromInt sec ++ "s"

        n ->
            let
                s =
                    sec - (n * 60)
            in
            fromMinutes n ++ ":" ++ num s


fromMinutes : Int -> String
fromMinutes min =
    case min // 60 of
        0 ->
            num min

        n ->
            let
                m =
                    min - (n * 60)
            in
            num n ++ ":" ++ num m


num : Int -> String
num n =
    String.fromInt n
        |> (++)
            (if n < 10 then
                "0"

             else
                ""
            )
