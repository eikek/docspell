{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.CalEvent exposing
    ( CalEvent
    , everyMonth
    , fromEvent
    , makeEvent
    )

import Data.TimeZone exposing (TimeZone)
import Util.Maybe


type alias CalEvent =
    { weekday : Maybe String
    , year : String
    , month : String
    , day : String
    , hour : String
    , minute : String
    , timeZone : TimeZone
    }


everyMonth : CalEvent
everyMonth =
    CalEvent Nothing "*" "*" "01" "00" "00" Data.TimeZone.utc


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
                ++ " "
                ++ Data.TimeZone.toName ev.timeZone
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

        foldChanges : List (CalEvent -> Maybe CalEvent) -> Maybe CalEvent
        foldChanges list =
            List.foldl (\fmc -> \c -> Maybe.andThen fmc c) (Just init) list
    in
    case parts of
        wd :: date :: time :: tz :: [] ->
            foldChanges
                [ fromWeekDays wd
                , fromDate date
                , fromTime time
                , fromTimeZone tz
                ]

        a :: b :: c :: [] ->
            if startsWithWeekday a then
                foldChanges
                    [ fromWeekDays a
                    , fromDate b
                    , fromTime c
                    ]

            else
                foldChanges
                    [ fromDate a
                    , fromTime b
                    , fromTimeZone c
                    ]

        date :: time :: [] ->
            foldChanges
                [ fromDate date
                , fromTime time
                ]

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


fromTimeZone : String -> CalEvent -> Maybe CalEvent
fromTimeZone tzStr ev =
    Data.TimeZone.get tzStr
        |> Maybe.map (\tz -> { ev | timeZone = tz })


fromWeekDays : String -> CalEvent -> Maybe CalEvent
fromWeekDays str ce =
    if startsWithWeekday str then
        Just (withWeekday str ce)

    else
        Nothing


withWeekday : String -> CalEvent -> CalEvent
withWeekday wd ev =
    { ev | weekday = Util.Maybe.fromString wd }


weekDays : List String
weekDays =
    [ "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" ]


startsWithWeekday : String -> Bool
startsWithWeekday str =
    List.any (\a -> String.startsWith a str) weekDays
