{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.List exposing
    ( changePosition
    , distinct
    , dropRight
    , find
    , findIndexed
    , findNext
    , findPrev
    , get
    , removeByIndex
    , replaceByIndex
    , sliding
    )

import Html.Attributes exposing (list)


removeByIndex : Int -> List a -> List a
removeByIndex index list =
    List.indexedMap
        (\idx ->
            \e ->
                if idx == index then
                    Nothing

                else
                    Just e
        )
        list
        |> List.filterMap identity


replaceByIndex : Int -> a -> List a -> List a
replaceByIndex index element list =
    let
        repl idx e =
            if idx == index then
                element

            else
                e
    in
    List.indexedMap repl list


changePosition : Int -> Int -> List a -> List a
changePosition source target list =
    let
        len =
            List.length list

        noChange =
            source == target || source + 1 == target

        outOfBounds n =
            n < 0 || n >= len

        concat el acc =
            let
                idx =
                    Tuple.first el

                ela =
                    Tuple.second el
            in
            if idx == source then
                ( target, ela ) :: acc

            else if idx >= target then
                ( idx + 1, ela ) :: acc

            else
                ( idx, ela ) :: acc
    in
    if noChange || outOfBounds source || outOfBounds target then
        list

    else
        List.indexedMap Tuple.pair list
            |> List.foldl concat []
            |> List.sortBy Tuple.first
            |> List.map Tuple.second


get : List a -> Int -> Maybe a
get list index =
    if index < 0 then
        Nothing

    else
        case list of
            [] ->
                Nothing

            x :: xs ->
                if index == 0 then
                    Just x

                else
                    get xs (index - 1)


find : (a -> Bool) -> List a -> Maybe a
find pred list =
    findIndexed pred list |> Maybe.map Tuple.first


findIndexed : (a -> Bool) -> List a -> Maybe ( a, Int )
findIndexed pred list =
    findIndexed1 pred list 0


findIndexed1 : (a -> Bool) -> List a -> Int -> Maybe ( a, Int )
findIndexed1 pred list index =
    case list of
        [] ->
            Nothing

        x :: xs ->
            if pred x then
                Just ( x, index )

            else
                findIndexed1 pred xs (index + 1)


distinct : List a -> List a
distinct list =
    List.reverse <|
        List.foldl
            (\a ->
                \r ->
                    if List.member a r then
                        r

                    else
                        a :: r
            )
            []
            list


findPrev : (a -> Bool) -> List a -> Maybe a
findPrev pred list =
    findIndexed pred list
        |> Maybe.map Tuple.second
        |> Maybe.map (\i -> i - 1)
        |> Maybe.andThen (get list)


findNext : (a -> Bool) -> List a -> Maybe a
findNext pred list =
    findIndexed pred list
        |> Maybe.map Tuple.second
        |> Maybe.map (\i -> i + 1)
        |> Maybe.andThen (get list)


dropRight : Int -> List a -> List a
dropRight n list =
    List.reverse list
        |> List.drop n
        |> List.reverse


sliding : (a -> a -> b) -> List a -> List b
sliding f list =
    let
        windows =
            case list of
                _ :: xs ->
                    List.map2 Tuple.pair list xs

                _ ->
                    []
    in
    List.map (\( e1, e2 ) -> f e1 e2) windows
