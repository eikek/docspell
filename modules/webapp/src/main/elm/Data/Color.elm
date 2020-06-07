module Data.Color exposing
    ( Color
    , all
    , allString
    , fromString
    , toString
    )


type Color
    = Red
    | Orange
    | Yellow
    | Olive
    | Green
    | Teal
    | Blue
    | Violet
    | Purple
    | Pink
    | Brown
    | Grey
    | Black


all : List Color
all =
    [ Red
    , Orange
    , Yellow
    , Olive
    , Green
    , Teal
    , Blue
    , Violet
    , Purple
    , Pink
    , Brown
    , Grey
    , Black
    ]


allString : List String
allString =
    List.map toString all


fromString : String -> Maybe Color
fromString str =
    case String.toLower str of
        "red" ->
            Just Red

        "orange" ->
            Just Orange

        "yellow" ->
            Just Yellow

        "olive" ->
            Just Olive

        "green" ->
            Just Green

        "teal" ->
            Just Teal

        "blue" ->
            Just Blue

        "violet" ->
            Just Violet

        "purple" ->
            Just Purple

        "pink" ->
            Just Pink

        "brown" ->
            Just Brown

        "grey" ->
            Just Grey

        "black" ->
            Just Black

        _ ->
            Nothing


toString : Color -> String
toString color =
    case color of
        Red ->
            "red"

        Orange ->
            "orange"

        Yellow ->
            "yellow"

        Olive ->
            "olive"

        Green ->
            "green"

        Teal ->
            "teal"

        Blue ->
            "blue"

        Violet ->
            "violet"

        Purple ->
            "purple"

        Pink ->
            "pink"

        Brown ->
            "brown"

        Grey ->
            "grey"

        Black ->
            "black"
