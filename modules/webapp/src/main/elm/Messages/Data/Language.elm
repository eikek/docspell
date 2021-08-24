{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Data.Language exposing
    ( de
    , gb
    )

import Data.Language exposing (Language(..))


gb : Language -> String
gb lang =
    case lang of
        German ->
            "German"

        English ->
            "English"

        French ->
            "French"

        Italian ->
            "Italian"

        Spanish ->
            "Spanish"

        Portuguese ->
            "Portuguese"

        Czech ->
            "Czech"

        Danish ->
            "Danish"

        Finnish ->
            "Finnish"

        Norwegian ->
            "Norwegian"

        Swedish ->
            "Swedish"

        Russian ->
            "Russian"

        Romanian ->
            "Romanian"

        Dutch ->
            "Dutch"

        Latvian ->
            "Latvian"

        Japanese ->
            "Japanese"

        Hebrew ->
            "Hebrew"


de : Language -> String
de lang =
    case lang of
        German ->
            "Deutsch"

        English ->
            "Englisch"

        French ->
            "Französisch"

        Italian ->
            "Italienisch"

        Spanish ->
            "Spanisch"

        Portuguese ->
            "Portugiesisch"

        Czech ->
            "Tschechisch"

        Danish ->
            "Dänisch"

        Finnish ->
            "Finnisch"

        Norwegian ->
            "Norwegisch"

        Swedish ->
            "Schwedisch"

        Russian ->
            "Russisch"

        Romanian ->
            "Romänisch"

        Dutch ->
            "Niederländisch"

        Latvian ->
            "Lettisch"

        Japanese ->
            "Japanisch"

        Hebrew ->
            "Hebräisch"
