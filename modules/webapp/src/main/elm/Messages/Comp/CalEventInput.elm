{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CalEventInput exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Comp.HttpError
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { weekday : String
    , year : String
    , month : String
    , day : String
    , hour : String
    , minute : String
    , error : String
    , schedule : String
    , next : String
    , formatDateTime : Int -> String
    , httpError : Http.Error -> String
    }


gb : Texts
gb =
    { weekday = "Weekday"
    , year = "Year"
    , month = "Month"
    , day = "Day"
    , hour = "Hour"
    , minute = "Minute"
    , error = "Error"
    , schedule = "Schedule"
    , next = "Next"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English
    , httpError = Messages.Comp.HttpError.gb
    }


de : Texts
de =
    { weekday = "Wochentag"
    , year = "Jahr"
    , month = "Monat"
    , day = "Tag"
    , hour = "Stunde"
    , minute = "Minute"
    , error = "Fehler"
    , schedule = "Zeitplan"
    , next = "Nächste Zeiten"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German
    , httpError = Messages.Comp.HttpError.de
    }
