{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.OrgManage exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.OrgForm
import Messages.Comp.OrgTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , orgForm : Messages.Comp.OrgForm.Texts
    , orgTable : Messages.Comp.OrgTable.Texts
    , httpError : Http.Error -> String
    , newOrganization : String
    , createNewOrganization : String
    , reallyDeleteOrg : String
    , deleteThisOrg : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , orgForm = Messages.Comp.OrgForm.gb
    , orgTable = Messages.Comp.OrgTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newOrganization = "New Organization"
    , createNewOrganization = "Create a new organization"
    , reallyDeleteOrg = "Really delete this organization?"
    , deleteThisOrg = "Delete this organization"
    , correctFormErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , orgForm = Messages.Comp.OrgForm.de
    , orgTable = Messages.Comp.OrgTable.de
    , httpError = Messages.Comp.HttpError.de
    , newOrganization = "Neue Organisation"
    , createNewOrganization = "Neue Organisation anlegen"
    , reallyDeleteOrg = "Die Organisation wirklich löschen?"
    , deleteThisOrg = "Organisation löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , orgForm = Messages.Comp.OrgForm.fr
    , orgTable = Messages.Comp.OrgTable.fr
    , httpError = Messages.Comp.HttpError.fr
    , newOrganization = "Nouvelle organisation"
    , createNewOrganization = "Créer une nouvelle organisation"
    , reallyDeleteOrg = "Confirmer la suppression de cette organisation"
    , deleteThisOrg = "Supprimer cette organisation"
    , correctFormErrors = "Veuillez corriger les erreurs du formulaire."
    }
