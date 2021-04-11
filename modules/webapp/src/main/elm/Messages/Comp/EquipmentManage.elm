module Messages.Comp.EquipmentManage exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.EquipmentForm
import Messages.Comp.EquipmentTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , equipmentTable : Messages.Comp.EquipmentTable.Texts
    , equipmentForm : Messages.Comp.EquipmentForm.Texts
    , createNewEquipment : String
    , newEquipment : String
    , reallyDeleteEquipment : String
    , deleteThisEquipment : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , equipmentTable = Messages.Comp.EquipmentTable.gb
    , equipmentForm = Messages.Comp.EquipmentForm.gb
    , createNewEquipment = "Create a new equipment"
    , newEquipment = "New Equipment"
    , reallyDeleteEquipment = "Really delete this equipment?"
    , deleteThisEquipment = "Delete this equipment"
    }
