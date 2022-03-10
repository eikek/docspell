{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.SharePasswordForm exposing (Texts, de, gb, fr)

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
    , passwordFailed = "Password is wrong"
    }


de : Texts
de =
    { httpError = Messages.Comp.HttpError.de
    , passwordRequired = "Passwort benötigt"
    , password = "Passwort"
    , passwordSubmitButton = "Submit"
    , passwordFailed = "Das Passwort ist falsch"
    }

fr : Texts
fr =
    { httpError = Messages.Comp.HttpError.fr
    , passwordRequired = "Mot de passe requis"
    , password = "Mot de passe"
    , passwordSubmitButton = "Envoyer"
    , passwordFailed = "Le mot de passe est faux"
    }
