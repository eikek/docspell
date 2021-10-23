{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.UserManage exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.UserForm
import Messages.Comp.UserTable


type alias Texts =
    { userTable : Messages.Comp.UserTable.Texts
    , userForm : Messages.Comp.UserForm.Texts
    , httpError : Http.Error -> String
    , users : String
    , newUser : String
    , addNewUser : String
    , reallyDeleteUser : String
    , createNewUser : String
    , basics : Messages.Basics.Texts
    , deleteThisUser : String
    , pleaseCorrectErrors : String
    , notDeleteCurrentUser : String
    , folders : String
    , sentMails : String
    , shares : String
    , deleteFollowingData : String
    }


gb : Texts
gb =
    { userTable = Messages.Comp.UserTable.gb
    , userForm = Messages.Comp.UserForm.gb
    , basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , users = "Users"
    , newUser = "New user"
    , addNewUser = "Add new user"
    , reallyDeleteUser = "Really delete this user?"
    , createNewUser = "Create new user"
    , deleteThisUser = "Delete this user"
    , pleaseCorrectErrors = "Please correct the errors in the form."
    , notDeleteCurrentUser = "You can't delete the user you are currently logged in with."
    , folders = "Folders"
    , sentMails = "sent mails"
    , shares = "shares"
    , deleteFollowingData = "The following data will be deleted"
    }


de : Texts
de =
    { userTable = Messages.Comp.UserTable.de
    , userForm = Messages.Comp.UserForm.de
    , basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , users = "Benutzer"
    , newUser = "Neuer Benutzer"
    , addNewUser = "Neuen Benutzen hinzufügen"
    , reallyDeleteUser = "Den Benutzer wirklich löschen?"
    , createNewUser = "Neuen Benutzer erstellen"
    , deleteThisUser = "Benutzer löschen"
    , pleaseCorrectErrors = "Bitte korrigiere die Fehler im Formular."
    , notDeleteCurrentUser = "Der aktuelle Benutzer kann nicht gelöscht werden."
    , folders = "Ordner"
    , sentMails = "gesendete E-Mails"
    , shares = "Freigaben"
    , deleteFollowingData = "Die folgenden Daten werden auch gelöscht"
    }
