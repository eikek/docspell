module Messages.LanguageData exposing (..)

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
