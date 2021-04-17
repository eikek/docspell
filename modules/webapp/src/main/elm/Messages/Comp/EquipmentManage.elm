module Messages.Comp.EquipmentManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.EquipmentForm
import Messages.Comp.EquipmentTable
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , equipmentTable : Messages.Comp.EquipmentTable.Texts
    , equipmentForm : Messages.Comp.EquipmentForm.Texts
    , httpError : Http.Error -> String
    , createNewEquipment : String
    , newEquipment : String
    , reallyDeleteEquipment : String
    , deleteThisEquipment : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , equipmentTable = Messages.Comp.EquipmentTable.gb
    , equipmentForm = Messages.Comp.EquipmentForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , createNewEquipment = "Create a new equipment"
    , newEquipment = "New Equipment"
    , reallyDeleteEquipment = "Really delete this equipment?"
    , deleteThisEquipment = "Delete this equipment"
    , correctFormErrors = "Please correct the errors in the form."
    }
