module Util.Time exposing (formatIsoDateTime)

import DateFormat
import Time exposing (Posix, Zone, utc)


isoDateTimeFormatter : Zone -> Posix -> String
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


timeZone : Zone
timeZone =
    utc


formatIsoDateTime : Int -> String
formatIsoDateTime millis =
    Time.millisToPosix millis
        |> isoDateTimeFormatter timeZone
