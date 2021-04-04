module Messages.CustomFieldManageComp exposing (..)

import Messages.Basics
import Messages.CustomFieldFormComp
import Messages.CustomFieldTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , fieldForm : Messages.CustomFieldFormComp.Texts
    , fieldTable : Messages.CustomFieldTableComp.Texts
    , addCustomField : String
    , newCustomField : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , fieldForm = Messages.CustomFieldFormComp.gb
    , fieldTable = Messages.CustomFieldTableComp.gb
    , addCustomField = "Add a new custom field"
    , newCustomField = "New custom field"
    }
