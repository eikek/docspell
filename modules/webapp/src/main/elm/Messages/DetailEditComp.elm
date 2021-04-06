module Messages.DetailEditComp exposing (..)

import Messages.Basics
import Messages.CustomFieldFormComp
import Messages.EquipmentFormComp
import Messages.OrgFormComp
import Messages.PersonFormComp
import Messages.TagFormComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagForm : Messages.TagFormComp.Texts
    , personForm : Messages.PersonFormComp.Texts
    , orgForm : Messages.OrgFormComp.Texts
    , equipmentForm : Messages.EquipmentFormComp.Texts
    , customFieldForm : Messages.CustomFieldFormComp.Texts
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagForm = Messages.TagFormComp.gb
    , personForm = Messages.PersonFormComp.gb
    , orgForm = Messages.OrgFormComp.gb
    , equipmentForm = Messages.EquipmentFormComp.gb
    , customFieldForm = Messages.CustomFieldFormComp.gb
    }
