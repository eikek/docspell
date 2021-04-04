module Messages.EquipmentManageComp exposing (..)

import Messages.Basics
import Messages.EquipmentFormComp
import Messages.EquipmentTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , equipmentTable : Messages.EquipmentTableComp.Texts
    , equipmentForm : Messages.EquipmentFormComp.Texts
    , createNewEquipment : String
    , newEquipment : String
    , reallyDeleteEquipment : String
    , deleteThisEquipment : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , equipmentTable = Messages.EquipmentTableComp.gb
    , equipmentForm = Messages.EquipmentFormComp.gb
    , createNewEquipment = "Create a new equipment"
    , newEquipment = "New Equipment"
    , reallyDeleteEquipment = "Really delete this equipment?"
    , deleteThisEquipment = "Delete this equipment"
    }
