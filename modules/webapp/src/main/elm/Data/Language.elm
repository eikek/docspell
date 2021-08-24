{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.Language exposing
    ( Language(..)
    , all
    , fromString
    , toIso3
    )


type Language
    = German
    | English
    | French
    | Italian
    | Spanish
    | Portuguese
    | Czech
    | Danish
    | Finnish
    | Norwegian
    | Swedish
    | Russian
    | Romanian
    | Dutch
    | Latvian
    | Japanese
    | Hebrew


fromString : String -> Maybe Language
fromString str =
    if str == "deu" || str == "de" || str == "german" then
        Just German

    else if str == "eng" || str == "en" || str == "english" then
        Just English

    else if str == "fra" || str == "fr" || str == "french" then
        Just French

    else if str == "ita" || str == "it" || str == "italian" then
        Just Italian

    else if str == "spa" || str == "es" || str == "spanish" then
        Just Spanish

    else if str == "por" || str == "pt" || str == "portuguese" then
        Just Portuguese

    else if str == "ces" || str == "cs" || str == "czech" then
        Just Czech

    else if str == "dan" || str == "da" || str == "danish" then
        Just Danish

    else if str == "nld" || str == "nd" || str == "dutch" then
        Just Dutch

    else if str == "fin" || str == "fi" || str == "finnish" then
        Just Finnish

    else if str == "nor" || str == "no" || str == "norwegian" then
        Just Norwegian

    else if str == "swe" || str == "sv" || str == "swedish" then
        Just Swedish

    else if str == "rus" || str == "ru" || str == "russian" then
        Just Russian

    else if str == "ron" || str == "ro" || str == "romanian" then
        Just Romanian

    else if str == "lav" || str == "lv" || str == "latvian" then
        Just Latvian

    else if str == "jpn" || str == "ja" || str == "japanese" then
        Just Japanese

    else if str == "heb" || str == "he" || str == "hebrew" then
        Just Hebrew

    else
        Nothing


toIso3 : Language -> String
toIso3 lang =
    case lang of
        German ->
            "deu"

        English ->
            "eng"

        French ->
            "fra"

        Italian ->
            "ita"

        Spanish ->
            "spa"

        Portuguese ->
            "por"

        Czech ->
            "ces"

        Danish ->
            "dan"

        Finnish ->
            "fin"

        Norwegian ->
            "nor"

        Swedish ->
            "swe"

        Russian ->
            "rus"

        Romanian ->
            "ron"

        Dutch ->
            "nld"

        Latvian ->
            "lav"

        Japanese ->
            "jpn"

        Hebrew ->
            "heb"


all : List Language
all =
    [ German
    , English
    , French
    , Italian
    , Spanish
    , Portuguese
    , Czech
    , Dutch
    , Danish
    , Finnish
    , Norwegian
    , Swedish
    , Russian
    , Romanian
    , Latvian
    , Japanese
    , Hebrew
    ]
