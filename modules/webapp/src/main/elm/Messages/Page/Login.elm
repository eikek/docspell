{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Login exposing
    ( Texts
    , de
    , fr
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
    , oidcLogoutPending : String
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
    , oidcLogoutPending = "You have been logged out from Docspell, but you may still be logged in at your authentication provider! Make sure to logout there as well, or login again by clicking the link below."
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
    , oidcLogoutPending = "Du wurdest von Docspell abgemeldet, aber evtl. bist du immernoch bei deinem Authentifizierungs-Provider angemeldet! Melde dich auch dort ab, oder logge dich wieder zu Docspell ein indem du den Link unten klickst."
    }



--- TODO french translation


fr : Texts
fr =
    { httpError = Messages.Comp.HttpError.fr
    , loginToDocspell = "Connexion à  Docspell"
    , username = "Identifiant"
    , collectiveSlashLogin = "Groupe / Utilisateur"
    , password = "Mot de passe"
    , rememberMe = "Se souvenir de moi"
    , loginPlaceholder = "Identifiant"
    , passwordPlaceholder = "Mot de passe"
    , loginButton = "Identifiant"
    , loginSuccessful = "Identification réussie"
    , noAccount = "Pas de compte ?"
    , signupLink = "S'incrire!"
    , otpCode = "Code d'authentification"
    , or = "Ou"
    , oidcLogoutPending = "You have been logged out from Docspell, but you may still be logged in at your authentication provider! Make sure to logout there as well, or login again by clicking the link below."
    }
