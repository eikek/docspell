module Messages.Data.CustomFieldType exposing (gb)

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
