{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.CalEvent exposing
    ( CalEvent
    , everyMonth
    , fromEvent
    , makeEvent
    )

import Util.Maybe


type alias CalEvent =
    { weekday : Maybe String
    , year : String
    , month : String
    , day : String
    , hour : String
    , minute : String
    }


everyMonth : CalEvent
everyMonth =
    CalEvent Nothing "*" "*" "01" "00" "00"


makeEvent : CalEvent -> String
makeEvent ev =
    let
        datetime =
            ev.year
                ++ "-"
                ++ ev.month
                ++ "-"
                ++ ev.day
                ++ " "
                ++ ev.hour
                ++ ":"
                ++ ev.minute
    in
    case ev.weekday of
        Just wd ->
            wd ++ " " ++ datetime

        Nothing ->
            datetime


fromEvent : String -> Maybe CalEvent
fromEvent str =
    let
        init =
            everyMonth

        parts =
            String.split " " str
    in
    case parts of
        wd :: date :: time :: [] ->
            Maybe.andThen
                (fromDate date)
                (fromTime time init)
                |> Maybe.map (withWeekday wd)

        date :: time :: [] ->
            Maybe.andThen
                (fromDate date)
                (fromTime time init)

        _ ->
            Nothing


fromDate : String -> CalEvent -> Maybe CalEvent
fromDate date ev =
    let
        parts =
            String.split "-" date
    in
    case parts of
        y :: m :: d :: [] ->
            Just
                { ev
                    | year = y
                    , month = m
                    , day = d
                }

        _ ->
            Nothing


fromTime : String -> CalEvent -> Maybe CalEvent
fromTime time ev =
    case String.split ":" time of
        h :: m :: _ :: [] ->
            Just { ev | hour = h, minute = m }

        h :: m :: [] ->
            Just { ev | hour = h, minute = m }

        _ ->
            Nothing


withWeekday : String -> CalEvent -> CalEvent
withWeekday wd ev =
    { ev | weekday = Util.Maybe.fromString wd }
