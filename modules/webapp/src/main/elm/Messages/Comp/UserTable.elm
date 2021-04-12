module Messages.Comp.UserTable exposing (Texts, gb)

import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , login : String
    , state : String
    , email : String
    , logins : String
    , lastLogin : String
    , formatDateTime : Int -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , login = "Login"
    , state = "State"
    , email = "E-Mail"
    , logins = "Logins"
    , lastLogin = "Last Login"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English
    }
