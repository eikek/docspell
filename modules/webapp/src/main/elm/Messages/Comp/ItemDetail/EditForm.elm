module Messages.Comp.ItemDetail.EditForm exposing (..)

import Messages.Basics
import Messages.Comp.CustomFieldMultiInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldInput : Messages.Comp.CustomFieldMultiInput.Texts
    , createNewCustomField : String
    , chooseDirection : String
    , selectPlaceholder : String
    , nameTab : String
    , dateTab : String
    , folderTab : String
    , folderNotOwnerWarning : String
    , customFieldsTab : String
    , dueDateTab : String
    , correspondentTab : String
    , organization : String
    , addNewOrg : String
    , editOrg : String
    , chooseOrg : String
    , addNewCorrespondentPerson : String
    , editPerson : String
    , personOrgInfo : String
    , concerningTab : String
    , addNewConcerningPerson : String
    , addNewEquipment : String
    , editEquipment : String
    , directionTab : String
    , suggestions : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.gb
    , createNewCustomField = "Create new custom field"
    , chooseDirection = "Choose a direction…"
    , selectPlaceholder = "Select…"
    , nameTab = "Name"
    , dateTab = "Date"
    , folderTab = "Folder"
    , folderNotOwnerWarning =
        """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
"""
    , customFieldsTab = "Custom Fields"
    , dueDateTab = "Due Date"
    , correspondentTab = "Correspondent"
    , organization = "Organization"
    , addNewOrg = "Add new organization"
    , editOrg = "Edit organization"
    , chooseOrg = "Choose an organization"
    , addNewCorrespondentPerson = "Add new correspondent person"
    , editPerson = "Edit person"
    , personOrgInfo = "The selected person doesn't belong to the selected organization."
    , concerningTab = "Concerning"
    , addNewConcerningPerson = "Add new concerning person"
    , addNewEquipment = "Add new equipment"
    , editEquipment = "Edit equipment"
    , directionTab = "Direction"
    , suggestions = "Suggestions"
    }
