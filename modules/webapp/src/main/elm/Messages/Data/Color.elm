{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Data.Color exposing
    ( de
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
            "Olive-Grün"

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
