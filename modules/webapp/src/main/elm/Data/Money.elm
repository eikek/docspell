module Data.Money exposing
    ( Money
    , format
    , fromString
    , roundMoney
    )


type alias Money =
    Float


fromString : String -> Result String Money
fromString str =
    let
        points =
            String.indexes "." str

        len =
            String.length str
    in
    case points of
        index :: [] ->
            if index == (len - 3) then
                String.toFloat str
                    |> Maybe.map Ok
                    |> Maybe.withDefault (Err "Two digits required after the dot.")

            else
                Err ("Two digits required after the dot: " ++ str)

        _ ->
            Err "One single dot + digits required for money."


format : Float -> String
format money =
    String.fromFloat (roundMoney money)


roundMoney : Float -> Float
roundMoney input =
    (round (input * 100) |> toFloat) / 100
