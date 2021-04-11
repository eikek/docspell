module Messages.Comp.UserTable exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , login : String
    , state : String
    , email : String
    , logins : String
    , lastLogin : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , login = "Login"
    , state = "State"
    , email = "E-Mail"
    , logins = "Logins"
    , lastLogin = "Last Login"
    }
