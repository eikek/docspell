{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AddonArchiveManage exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.AddonArchiveForm
import Messages.Comp.AddonArchiveTable
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , addonArchiveTable : Messages.Comp.AddonArchiveTable.Texts
    , addonArchiveForm : Messages.Comp.AddonArchiveForm.Texts
    , httpError : Http.Error -> String
    , newAddonArchive : String
    , reallyDeleteAddonArchive : String
    , createNewAddonArchive : String
    , deleteThisAddonArchive : String
    , correctFormErrors : String
    , installNow : String
    , updateNow : String
    , description : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , addonArchiveTable = Messages.Comp.AddonArchiveTable.gb
    , addonArchiveForm = Messages.Comp.AddonArchiveForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , newAddonArchive = "New Addon"
    , reallyDeleteAddonArchive = "Really delete this Addon?"
    , createNewAddonArchive = "Install new Addon"
    , deleteThisAddonArchive = "Delete this Addon"
    , correctFormErrors = "Please correct the errors in the form."
    , installNow = "Install Addon"
    , updateNow = "Update Addon"
    , description = "Description"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , addonArchiveTable = Messages.Comp.AddonArchiveTable.de
    , addonArchiveForm = Messages.Comp.AddonArchiveForm.de
    , httpError = Messages.Comp.HttpError.de
    , newAddonArchive = "Neues Addon"
    , reallyDeleteAddonArchive = "Dieses Addon wirklich entfernen?"
    , createNewAddonArchive = "Neues Addon installieren"
    , deleteThisAddonArchive = "Addon löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    , installNow = "Addon Installieren"
    , updateNow = "Addon aktualisieren"
    , description = "Beschreibung"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , addonArchiveTable = Messages.Comp.AddonArchiveTable.fr
    , addonArchiveForm = Messages.Comp.AddonArchiveForm.fr
    , httpError = Messages.Comp.HttpError.fr
    , newAddonArchive = "Nouveau favori"
    , reallyDeleteAddonArchive = "Confirmer la suppression de ce favori ?"
    , createNewAddonArchive = "Créer un nouveau favori"
    , deleteThisAddonArchive = "Supprimer ce favori"
    , correctFormErrors = "Veuillez corriger les erreurs du formulaire"
    , installNow = "Installation de l'addon"
    , updateNow = "Actualiser l'addon"
    , description = "Description"
    }
