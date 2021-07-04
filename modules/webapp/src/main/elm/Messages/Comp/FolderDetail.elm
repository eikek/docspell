{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.FolderDetail exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , reallyDeleteThisFolder : String
    , autoOwnerInfo : String
    , modifyInfo : String
    , notOwnerInfo : String
    , members : String
    , addMember : String
    , add : String
    , removeMember : String
    , deleteThisFolder : String
    , folderCreated : String
    , nameChangeSuccessful : String
    , deleteSuccessful : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , reallyDeleteThisFolder = "Really delete this folder?"
    , autoOwnerInfo = "You are automatically set as owner of this new folder."
    , modifyInfo = "Modify this folder by changing the name or add/remove members."
    , notOwnerInfo = "You are not the owner of this folder and therefore are not allowed to edit it."
    , members = "Members"
    , addMember = "Add a new member"
    , add = "Add"
    , removeMember = "Remove this member"
    , deleteThisFolder = "Delete this folder"
    , folderCreated = "Folder has been created."
    , nameChangeSuccessful = "Name has been changed."
    , deleteSuccessful = "Folder has been deleted."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , reallyDeleteThisFolder = "Den Ordner wirklich löschen?"
    , autoOwnerInfo = "Du wirst automatisch als Besizter des neuen Ordners gesetzt."
    , modifyInfo = "Der Ordnername sowie die Mitglieder können geändert werden."
    , notOwnerInfo = "Du bist nicht der Besitzer des Ordners und kannst ihn daher auch nicht ändern."
    , members = "Mitglieder"
    , addMember = "Neues Mitglied hinzufügen"
    , add = "Hinzufügen"
    , removeMember = "Mitglied entfernen"
    , deleteThisFolder = "Den Ordner löschen"
    , folderCreated = "Der Ordner wurde erstellt."
    , nameChangeSuccessful = "Der Name wurde aktualisiert."
    , deleteSuccessful = "Der Ordner wurde gelöscht."
    }
