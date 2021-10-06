module Messages.Comp.SharePasswordForm exposing (Texts, de, gb)

import Http
import Messages.Comp.HttpError


type alias Texts =
    { httpError : Http.Error -> String
    , passwordRequired : String
    , password : String
    , passwordSubmitButton : String
    , passwordFailed : String
    }


gb : Texts
gb =
    { httpError = Messages.Comp.HttpError.gb
    , passwordRequired = "Password required"
    , password = "Password"
    , passwordSubmitButton = "Submit"
    , passwordFailed = "Das Passwort ist falsch"
    }


de : Texts
de =
    { httpError = Messages.Comp.HttpError.de
    , passwordRequired = "Passwort benötigt"
    , password = "Passwort"
    , passwordSubmitButton = "Submit"
    , passwordFailed = "Password is wrong"
    }
