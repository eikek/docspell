{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.Color exposing
    ( de
    , fr
    , gb
    )

import Data.Color exposing (Color(..))


gb : Color -> String
gb color =
    case color of
        Red ->
            "Red"

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


de : Color -> String
de color =
    case color of
        Red ->
            "Rot"

        Orange ->
            "Orange"

        Yellow ->
            "Gelb"

        Olive ->
            "Olivgrün"

        Green ->
            "Grün"

        Teal ->
            "Blaugrün"

        Blue ->
            "Blau"

        Violet ->
            "Violett"

        Purple ->
            "Lila"

        Pink ->
            "Rosa"

        Brown ->
            "Braun"

        Grey ->
            "Grau"

        Black ->
            "Schwarz"


fr : Color -> String
fr color =
    case color of
        Red ->
            "Rouge"

        Orange ->
            "Orange"

        Yellow ->
            "Jaune"

        Olive ->
            "Olive"

        Green ->
            "Vert"

        Teal ->
            "Turquoise"

        Blue ->
            "Bleu"

        Violet ->
            "Mauve"

        Purple ->
            "Violet"

        Pink ->
            "Rose"

        Brown ->
            "Marron"

        Grey ->
            "Gris"

        Black ->
            "Noir"
