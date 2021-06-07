module Messages.Data.CustomFieldType exposing
    ( de
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
