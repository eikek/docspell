module Util.Time exposing (..)

import DateFormat
import Time exposing (Posix, Zone, utc)


dateFormatter : Zone -> Posix -> String
dateFormatter =
    DateFormat.format
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text ", "
        , DateFormat.yearNumber
        ]

dateFormatterShort: Zone -> Posix -> String
dateFormatterShort =
    DateFormat.format
        [ DateFormat.yearNumber
        , DateFormat.text "/"
        , DateFormat.monthFixed
        , DateFormat.text "/"
        , DateFormat.dayOfMonthFixed
        ]

timeFormatter: Zone -> Posix -> String
timeFormatter =
    DateFormat.format
        [ DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]

isoDateTimeFormatter: Zone -> Posix -> String
isoDateTimeFormatter =
    DateFormat.format
        [ DateFormat.yearNumber
        , DateFormat.text "-"
        , DateFormat.monthFixed
        , DateFormat.text "-"
        , DateFormat.dayOfMonthFixed
        , DateFormat.text "T"
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        , DateFormat.text ":"
        , DateFormat.secondFixed
        ]


timeZone: Zone
timeZone =
    utc

{- Format millis into "Wed, 10. Jan 2018, 18:57"
-}
formatDateTime: Int -> String
formatDateTime millis =
    (formatDate millis) ++ ", " ++ (formatTime millis)

formatIsoDateTime: Int -> String
formatIsoDateTime millis =
    Time.millisToPosix millis
        |> isoDateTimeFormatter timeZone

{- Format millis into "18:57". The current time (not the duration of
   the millis).
-}
formatTime: Int -> String
formatTime millis =
    Time.millisToPosix millis
        |> timeFormatter timeZone

{- Format millis into "Wed, 10. Jan 2018"
-}
formatDate: Int -> String
formatDate millis =
    Time.millisToPosix millis
        |> dateFormatter timeZone

formatDateShort: Int -> String
formatDateShort millis =
    Time.millisToPosix millis
        |> dateFormatterShort timeZone
