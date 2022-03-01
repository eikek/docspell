{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.DateFormat exposing
    ( format
    , formatDateLong
    , formatDateShort
    , formatDateTimeLong
    , formatDateTimeShort
    , formatIsoDateTimeUtc
    )

import DateFormat exposing (Token)
import DateFormat.Language as DL
import Messages.UiLanguage exposing (UiLanguage(..))
import Time
    exposing
        ( Month(..)
        , Weekday(..)
        , Zone
        )


type alias DateTimeMsg =
    { dateLong : List Token
    , dateShort : List Token
    , dateTimeLong : List Token
    , dateTimeShort : List Token
    , lang : DL.Language
    }


get : UiLanguage -> DateTimeMsg
get lang =
    case lang of
        English ->
            gb

        German ->
            de


format : UiLanguage -> (DateTimeMsg -> List Token) -> Int -> String
format lang pattern millis =
    let
        msg =
            get lang

        fmt =
            DateFormat.formatWithLanguage msg.lang (pattern msg)
    in
    fmt Time.utc (Time.millisToPosix millis)


formatDateTimeLong : UiLanguage -> Int -> String
formatDateTimeLong lang millis =
    format lang .dateTimeLong millis


formatDateLong : UiLanguage -> Int -> String
formatDateLong lang millis =
    format lang .dateLong millis


formatDateShort : UiLanguage -> Int -> String
formatDateShort lang millis =
    format lang .dateShort millis


formatDateTimeShort : UiLanguage -> Int -> String
formatDateTimeShort lang millis =
    format lang .dateTimeShort millis


isoDateTimeFormatter : List Token
isoDateTimeFormatter =
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
    , DateFormat.text "Z"
    ]


formatIsoDateTimeUtc : Int -> String
formatIsoDateTimeUtc millis =
    Time.millisToPosix millis
        |> DateFormat.format isoDateTimeFormatter Time.utc



--- Language Definitions


gb : DateTimeMsg
gb =
    { dateLong =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text ", "
        , DateFormat.yearNumber
        ]
    , dateShort =
        [ DateFormat.yearNumber
        , DateFormat.text "/"
        , DateFormat.monthFixed
        , DateFormat.text "/"
        , DateFormat.dayOfMonthFixed
        ]
    , dateTimeLong =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text ", "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , dateTimeShort =
        [ DateFormat.yearNumber
        , DateFormat.text "/"
        , DateFormat.monthFixed
        , DateFormat.text "/"
        , DateFormat.dayOfMonthFixed
        , DateFormat.text " "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = DL.english
    }


de : DateTimeMsg
de =
    { dateLong =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.yearNumber
        ]
    , dateShort =
        [ DateFormat.dayOfMonthFixed
        , DateFormat.text "."
        , DateFormat.monthFixed
        , DateFormat.text "."
        , DateFormat.yearNumber
        ]
    , dateTimeLong =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ". "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , dateTimeShort =
        [ DateFormat.dayOfMonthFixed
        , DateFormat.text "."
        , DateFormat.monthFixed
        , DateFormat.text "."
        , DateFormat.yearNumber
        , DateFormat.text " "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = german
    }


{-| French date formats; must be reviewed!
-}
fr : DateTimeMsg
fr =
    { dateLong =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.yearNumber
        ]
    , dateShort =
        [ DateFormat.dayOfMonthFixed
        , DateFormat.text "."
        , DateFormat.monthFixed
        , DateFormat.text "."
        , DateFormat.yearNumber
        ]
    , dateTimeLong =
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ". "
        , DateFormat.dayOfMonthSuffix
        , DateFormat.text " "
        , DateFormat.monthNameFull
        , DateFormat.text " "
        , DateFormat.yearNumber
        , DateFormat.text ", "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , dateTimeShort =
        [ DateFormat.dayOfMonthFixed
        , DateFormat.text "."
        , DateFormat.monthFixed
        , DateFormat.text "."
        , DateFormat.yearNumber
        , DateFormat.text " "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
    , lang = french
    }



--- Languages for the DateFormat module
-- French


{-| The French language!
-}
french : DL.Language
french =
    DL.Language
        toFrenchMonthName
        toFrenchMonthAbbreviation
        toFrenchWeekdayName
        (toFrenchWeekdayName >> String.left 3)
        toEnglishAmPm
        toFrenchOrdinalSuffix


toFrenchMonthName : Month -> String
toFrenchMonthName month =
    case month of
        Jan ->
            "janvier"

        Feb ->
            "février"

        Mar ->
            "mars"

        Apr ->
            "avril"

        May ->
            "mai"

        Jun ->
            "juin"

        Jul ->
            "juillet"

        Aug ->
            "août"

        Sep ->
            "septembre"

        Oct ->
            "octobre"

        Nov ->
            "novembre"

        Dec ->
            "décembre"


toFrenchMonthAbbreviation : Month -> String
toFrenchMonthAbbreviation month =
    case month of
        Jan ->
            "janv"

        Feb ->
            "févr"

        Mar ->
            "mars"

        Apr ->
            "avr"

        May ->
            "mai"

        Jun ->
            "juin"

        Jul ->
            "juil"

        Aug ->
            "août"

        Sep ->
            "sept"

        Oct ->
            "oct"

        Nov ->
            "nov"

        Dec ->
            "déc"


toFrenchWeekdayName : Weekday -> String
toFrenchWeekdayName weekday =
    case weekday of
        Mon ->
            "lundi"

        Tue ->
            "mardi"

        Wed ->
            "mercredi"

        Thu ->
            "jeudi"

        Fri ->
            "vendredi"

        Sat ->
            "samedi"

        Sun ->
            "dimanche"


toFrenchOrdinalSuffix : Int -> String
toFrenchOrdinalSuffix n =
    if n == 1 then
        "er"

    else
        ""



-- German


{-| The German language!
-}
german : DL.Language
german =
    let
        withDot str =
            str ++ "."
    in
    DL.Language
        toGermanMonthName
        (toGermanMonthName >> String.left 3 >> withDot)
        toGermanWeekdayName
        (toGermanWeekdayName >> String.left 2 >> withDot)
        toEnglishAmPm
        (\_ -> ".")


toGermanMonthName : Month -> String
toGermanMonthName month =
    case month of
        Jan ->
            "Januar"

        Feb ->
            "Februar"

        Mar ->
            "März"

        Apr ->
            "April"

        May ->
            "Mai"

        Jun ->
            "Juni"

        Jul ->
            "Juli"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "Oktober"

        Nov ->
            "November"

        Dec ->
            "Dezember"


toGermanWeekdayName : Weekday -> String
toGermanWeekdayName weekday =
    case weekday of
        Mon ->
            "Montag"

        Tue ->
            "Dienstag"

        Wed ->
            "Mittwoch"

        Thu ->
            "Donnerstag"

        Fri ->
            "Freitag"

        Sat ->
            "Samstag"

        Sun ->
            "Sonntag"



--- Copy from DateFormat.Language


toEnglishAmPm : Int -> String
toEnglishAmPm hour =
    if hour > 11 then
        "pm"

    else
        "am"
