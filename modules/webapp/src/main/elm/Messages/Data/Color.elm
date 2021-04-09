module Messages.Data.Color exposing (..)

import Data.Color exposing (Color(..))


gb : Color -> String
gb color =
    case color of
        Red ->
            "Rot"

        Orange ->
            "Orange"

        Yellow ->
            "Yellow"

        Olive ->
            "Olive"

        Green ->
            "Green"

        Teal ->
            "Teal"

        Blue ->
            "Blue"

        Violet ->
            "Violet"

        Purple ->
            "Purple"

        Pink ->
            "Pink"

        Brown ->
            "Brown"

        Grey ->
            "Grey"

        Black ->
            "Black"
