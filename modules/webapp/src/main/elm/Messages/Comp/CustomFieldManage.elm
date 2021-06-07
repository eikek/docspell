module Messages.Comp.CustomFieldManage exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics
import Messages.Comp.CustomFieldForm
import Messages.Comp.CustomFieldTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , fieldForm : Messages.Comp.CustomFieldForm.Texts
    , fieldTable : Messages.Comp.CustomFieldTable.Texts
    , addCustomField : String
    , newCustomField : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , fieldForm = Messages.Comp.CustomFieldForm.gb
    , fieldTable = Messages.Comp.CustomFieldTable.gb
    , addCustomField = "Add a new custom field"
    , newCustomField = "New custom field"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , fieldForm = Messages.Comp.CustomFieldForm.de
    , fieldTable = Messages.Comp.CustomFieldTable.de
    , addCustomField = "Ein neues Benutzer-Feld anlegen"
    , newCustomField = "Neues Benutzer-Feld"
    }
