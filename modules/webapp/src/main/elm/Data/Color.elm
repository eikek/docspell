{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Data.Color exposing
    ( Color(..)
    , all
    , allString
    , fromString
    , toString
    , toString2
    , toStringFg2
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


toString2 : Color -> String
toString2 color =
    case color of
        Red ->
            "border "
                ++ "bg-red-700 border-red-700 text-white "
                ++ "dark:bg-red-500 dark:bg-opacity-30 dark:text-red-400 dark:border-red-400"

        Orange ->
            "border "
                ++ "bg-orange-600 border-orange-600 text-white "
                ++ "dark:bg-orange-600 dark:bg-opacity-30 dark:text-orange-400 dark:border-orange-400"

        Yellow ->
            "border "
                ++ "bg-yellow-500 border-yellow-500 text-white "
                ++ "dark:bg-yellow-500 dark:bg-opacity-30 dark:text-yellow-500 dark:border-yellow-500"

        Olive ->
            "border "
                ++ "bg-lime-600 border-lime-600 text-white "
                ++ "dark:bg-lime-600 dark:bg-opacity-30 dark:text-lime-400 dark:border-lime-400"

        Green ->
            "border "
                ++ "bg-green-400 border-green-400 text-white "
                ++ "dark:bg-green-600 dark:bg-opacity-30 dark:text-green-400 dark:border-green-400"

        Teal ->
            "border "
                ++ "bg-teal-600 border-teal-600 text-white "
                ++ "dark:bg-teal-600 dark:bg-opacity-30 dark:text-teal-400 dark:border-teal-400"

        Blue ->
            "border "
                ++ "bg-blue-600 border-blue-600 text-white "
                ++ "dark:bg-blue-600 dark:bg-opacity-30 dark:text-blue-400 dark:border-blue-400"

        Violet ->
            "border "
                ++ "bg-indigo-600 border-indigo-600 text-white "
                ++ "dark:bg-indigo-600 dark:bg-opacity-30 dark:text-indigo-400 dark:border-indigo-400"

        Purple ->
            "border "
                ++ "bg-purple-600 border-purple-600 text-white "
                ++ "dark:bg-purple-600 dark:bg-opacity-30 dark:text-purple-400 dark:border-purple-400"

        Pink ->
            "border "
                ++ "bg-pink-600 border-pink-600 text-white "
                ++ "dark:bg-pink-600 dark:bg-opacity-30 dark:text-pink-400 dark:border-pink-400"

        Brown ->
            "border "
                ++ "bg-amber-700 border-amber-700 text-white "
                ++ "dark:bg-amber-900 dark:bg-opacity-30 dark:text-amber-700 dark:border-amber-700"

        Grey ->
            "border "
                ++ "bg-gray-500 border-gray-500 text-white "
                ++ "dark:bg-gray-500 dark:bg-opacity-30 dark:text-gray-400 dark:border-gray-400"

        Black ->
            "border "
                ++ "bg-black border-black text-white dark:bg-opacity-90 "


toStringFg2 : Color -> String
toStringFg2 color =
    case color of
        Red ->
            "text-red-700 dark:text-red-400"

        Orange ->
            "text-orange-600 dark:text-orange-400"

        Yellow ->
            "text-yellow-500 dark:text-yellow-500"

        Olive ->
            "text-lime-600 dark:text-lime-400"

        Green ->
            "text-green-400 dark:text-green-400"

        Teal ->
            "text-teal-600 dark:text-teal-400"

        Blue ->
            "text-blue-600 dark:text-blue-400 "

        Violet ->
            "text-indigo-600 dark:text-indigo-400 "

        Purple ->
            "text-purple-600 dark:text-purple-400"

        Pink ->
            "text-pink-600 text:text-pink-400"

        Brown ->
            "text-amber-700 dark:text-amber-700"

        Grey ->
            "text-gray-500 dark:text-gray-400"

        Black ->
            "text-black "
