{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Login exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Comp.HttpError


type alias Texts =
    { httpError : Http.Error -> String
    , loginToDocspell : String
    , username : String
    , collectiveSlashLogin : String
    , password : String
    , rememberMe : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    , otpCode : String
    , or : String
    }


gb : Texts
gb =
    { httpError = Messages.Comp.HttpError.gb
    , loginToDocspell = "Login to Docspell"
    , username = "Username"
    , collectiveSlashLogin = "Collective / Login"
    , password = "Password"
    , rememberMe = "Remember Me"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    , otpCode = "Authentication code"
    , or = "Or"
    }


de : Texts
de =
    { httpError = Messages.Comp.HttpError.de
    , loginToDocspell = "Docspell Anmeldung"
    , username = "Benutzer"
    , collectiveSlashLogin = "Kollektiv / Benutzer"
    , password = "Passwort"
    , rememberMe = "Anmeldung speichern"
    , loginPlaceholder = "Benutzer"
    , passwordPlaceholder = "Passwort"
    , loginButton = "Anmelden"
    , loginSuccessful = "Anmeldung erfolgreich"
    , noAccount = "Kein Konto?"
    , signupLink = "Hier registrieren!"
    , otpCode = "Authentifizierungscode"
    , or = "Oder"
    }
