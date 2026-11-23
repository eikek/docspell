{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CalEventInput exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Data.TimeZone exposing (TimeZone)
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


gb : TimeZone -> Texts
gb tz =
    { weekday = "Weekday"
    , year = "Year"
    , month = "Month"
    , day = "Day"
    , hour = "Hour"
    , minute = "Minute"
    , error = "Error"
    , schedule = "Schedule"
    , next = "Next"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English tz
    , httpError = Messages.Comp.HttpError.gb
    }


de : TimeZone -> Texts
de tz =
    { weekday = "Wochentag"
    , year = "Jahr"
    , month = "Monat"
    , day = "Tag"
    , hour = "Stunde"
    , minute = "Minute"
    , error = "Fehler"
    , schedule = "Zeitplan"
    , next = "Nächste Zeiten"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German tz
    , httpError = Messages.Comp.HttpError.de
    }


fr : TimeZone -> Texts
fr tz =
    { weekday = "Jour  de la semaine"
    , year = "Année"
    , month = "Mois"
    , day = "Jour"
    , hour = "Heure"
    , minute = "Minute"
    , error = "Erreur"
    , schedule = "Programmation"
    , next = "Suivant"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.French tz
    , httpError = Messages.Comp.HttpError.fr
    }


pt : TimeZone -> Texts
pt tz =
    { weekday = "Dia da semana"
    , year = "Ano"
    , month = "Mês"
    , day = "Dia"
    , hour = "Hora"
    , minute = "Minuto"
    , error = "Erro"
    , schedule = "Agendar"
    , next = "Próxima"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.Portuguese tz
    , httpError = Messages.Comp.HttpError.pt
    }
