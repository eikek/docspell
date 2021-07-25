{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.OrgManage exposing
    ( Texts
    , de
    , gb
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
