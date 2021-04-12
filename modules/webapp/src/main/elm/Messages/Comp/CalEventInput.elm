module Messages.Comp.CalEventInput exposing (Texts, gb)

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
    }
