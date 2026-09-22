{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.CustomFieldType exposing
    ( de
    , fr
    , ja
    , gb
    )

import Data.CustomFieldType exposing (CustomFieldType(..))


gb : CustomFieldType -> String
gb ft =
    case ft of
        Text ->
            "Text"

        Numeric ->
            "Numeric"

        Date ->
            "Date"

        Boolean ->
            "Boolean"

        Money ->
            "Money"


de : CustomFieldType -> String
de ft =
    case ft of
        Text ->
            "Text"

        Numeric ->
            "Numerisch"

        Date ->
            "Datum"

        Boolean ->
            "Boolean"

        Money ->
            "Geldbetrag"


fr : CustomFieldType -> String
fr ft =
    case ft of
        Text ->
            "Texte"

        Numeric ->
            "Numerique"

        Date ->
            "Date"

        Boolean ->
            "Booléen"

        Money ->
            "Monétaire"


ja : CustomFieldType -> String
ja ft =
    case ft of
        Text ->
            "テキスト"

        Numeric ->
            "数値"

        Date ->
            "日付"

        Boolean ->
            "論理演算"

        Money ->
            "お金"
