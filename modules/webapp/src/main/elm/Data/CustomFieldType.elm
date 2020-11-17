module Data.CustomFieldType exposing
    ( CustomFieldType(..)
    , all
    , asString
    , fromString
    , label
    )


type CustomFieldType
    = Text
    | Numeric
    | Date
    | Boolean
    | Money


all : List CustomFieldType
all =
    [ Text, Numeric, Date, Boolean, Money ]


asString : CustomFieldType -> String
asString ft =
    case ft of
        Text ->
            "text"

        Numeric ->
            "numeric"

        Date ->
            "date"

        Boolean ->
            "bool"

        Money ->
            "money"


label : CustomFieldType -> String
label ft =
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


fromString : String -> Maybe CustomFieldType
fromString str =
    case String.toLower str of
        "text" ->
            Just Text

        "numeric" ->
            Just Numeric

        "date" ->
            Just Date

        "bool" ->
            Just Boolean

        "money" ->
            Just Money

        _ ->
            Nothing
