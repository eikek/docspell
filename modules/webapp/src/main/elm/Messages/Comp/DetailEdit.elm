module Messages.Comp.DetailEdit exposing (Texts, gb)

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
    }
