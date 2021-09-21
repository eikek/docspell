{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DetailEdit exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.CustomFieldForm
import Messages.Comp.EquipmentForm
import Messages.Comp.HttpError
import Messages.Comp.OrgForm
import Messages.Comp.PersonForm
import Messages.Comp.TagForm


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagForm : Messages.Comp.TagForm.Texts
    , personForm : Messages.Comp.PersonForm.Texts
    , orgForm : Messages.Comp.OrgForm.Texts
    , equipmentForm : Messages.Comp.EquipmentForm.Texts
    , customFieldForm : Messages.Comp.CustomFieldForm.Texts
    , httpError : Http.Error -> String
    , submitSuccessful : String
    , missingRequiredFields : String
    , addTagHeader : String
    , addPersonHeader : String
    , addOrgHeader : String
    , addEquipmentHeader : String
    , addCustomFieldHeader : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagForm = Messages.Comp.TagForm.gb
    , personForm = Messages.Comp.PersonForm.gb
    , orgForm = Messages.Comp.OrgForm.gb
    , equipmentForm = Messages.Comp.EquipmentForm.gb
    , customFieldForm = Messages.Comp.CustomFieldForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , submitSuccessful = "Successfully saved."
    , missingRequiredFields = "Please fill required fields."
    , addTagHeader = "Add Tag"
    , addPersonHeader = "Add Person"
    , addOrgHeader = "Add Organization"
    , addEquipmentHeader = "Add Equipment"
    , addCustomFieldHeader = "Add Custom Field"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , tagForm = Messages.Comp.TagForm.de
    , personForm = Messages.Comp.PersonForm.de
    , orgForm = Messages.Comp.OrgForm.de
    , equipmentForm = Messages.Comp.EquipmentForm.de
    , customFieldForm = Messages.Comp.CustomFieldForm.de
    , httpError = Messages.Comp.HttpError.de
    , submitSuccessful = "Erfolgreich gespeichert."
    , missingRequiredFields = "Bitte die erforderlichen Felder ausfüllen."
    , addTagHeader = "Tag anlegen"
    , addPersonHeader = "Person anlegen"
    , addOrgHeader = "Organisation anlegen"
    , addEquipmentHeader = "Ausstattung anlegen"
    , addCustomFieldHeader = "Benutzerfeld anlegen"
    }
