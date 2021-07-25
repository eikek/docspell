{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.Money exposing
    ( Money
    , MoneyParseError(..)
    , format
    , fromString
    , normalizeInput
    , roundMoney
    )


type alias Money =
    Float


type MoneyParseError
    = RequireTwoDigitsAfterDot String
    | NoOrTooManyPoints String


fromString : String -> Result MoneyParseError Money
fromString str =
    let
        input =
            normalizeInput str

        points =
            String.indexes "." input

        len =
            String.length str
    in
    case points of
        index :: [] ->
            if index == (len - 3) then
                String.toFloat input
                    |> Maybe.map Ok
                    |> Maybe.withDefault (Err (RequireTwoDigitsAfterDot str))

            else
                Err (RequireTwoDigitsAfterDot str)

        _ ->
            Err (NoOrTooManyPoints str)


format : Float -> String
format money =
    String.fromFloat (roundMoney money)


roundMoney : Float -> Float
roundMoney input =
    (round (input * 100) |> toFloat) / 100


normalizeInput : String -> String
normalizeInput str =
    String.replace "," "." str
