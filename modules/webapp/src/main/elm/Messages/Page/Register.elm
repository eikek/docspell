{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Register exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , signupToDocspell : String
    , collectiveId : String
    , collective : String
    , userLogin : String
    , username : String
    , password : String
    , passwordRepeat : String
    , invitationKey : String
    , alreadySignedUp : String
    , signIn : String
    , registrationSuccessful : String
    , passwordsDontMatch : String
    , allFieldsRequired : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , signupToDocspell = "Signup to Docspell"
    , collectiveId = "Collective ID"
    , collective = "Collective"
    , userLogin = "User Login"
    , username = "Username"
    , password = "Password"
    , passwordRepeat = "Password (repeat)"
    , invitationKey = "Invitation Key"
    , alreadySignedUp = "Already signed up?"
    , signIn = "Sign in"
    , registrationSuccessful = "Registration successful."
    , passwordsDontMatch = "The passwords do not match."
    , allFieldsRequired = "All fields are required!"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , signupToDocspell = "Registrierung bei Docspell"
    , collectiveId = "Kollektiv"
    , collective = "Kollektiv"
    , userLogin = "Benutzername"
    , username = "Benutzername"
    , password = "Passwort"
    , passwordRepeat = "Passwort (Wiederholung)"
    , invitationKey = "Einladungs-ID"
    , alreadySignedUp = "Bereits registriert?"
    , signIn = "Anmelden"
    , registrationSuccessful = "Registratierung erfolgreich."
    , passwordsDontMatch = "Die Passwörten stimmen nicht überein."
    , allFieldsRequired = "Alle Felder müssen ausgefüllt werden!"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , signupToDocspell = "S'inscrire à Docspell"
    , collectiveId = "Groupe ID"
    , collective = "Groupe"
    , userLogin = "Identifiant Utilisateur"
    , username = "Utilisateur"
    , password = "Mot de passe"
    , passwordRepeat = "Mot de passe (confirmation)"
    , invitationKey = "Clé d'invitation"
    , alreadySignedUp = "Déja inscrit ?"
    , signIn = "Se Connecter"
    , registrationSuccessful = "Inscription accomplie."
    , passwordsDontMatch = "Les mots de passe ne correspondent pas."
    , allFieldsRequired = "Tous les champs sont requis !"
    }
