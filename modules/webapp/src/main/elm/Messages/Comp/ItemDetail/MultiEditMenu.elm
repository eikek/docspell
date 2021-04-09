module Messages.Comp.ItemDetail.MultiEditMenu exposing (..)

import Messages.Basics
import Messages.Comp.CustomFieldMultiInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagModeAddInfo : String
    , tagModeRemoveInfo : String
    , tagModeReplaceInfo : String
    , selectPlaceholder : String
    , chooseDirection : String
    , confirmUnconfirm : String
    , confirm : String
    , unconfirm : String
    , changeTagMode : String
    , folderTab : String
    , folderNotOwnerWarning : String
    , customFieldsTab : String
    , dateTab : String
    , dueDateTab : String
    , correspondentTab : String
    , organization : String
    , person : String
    , concerningTab : String
    , equipment : String
    , directionTab : String
    , nameTab : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagModeAddInfo = "Tags chosen here are *added* to all selected items."
    , tagModeRemoveInfo = "Tags chosen here are *removed* from all selected items."
    , tagModeReplaceInfo = "Tags chosen here *replace* those on selected items."
    , selectPlaceholder = "Select…"
    , chooseDirection = "Choose a direction…"
    , confirmUnconfirm = "Confirm/Unconfirm item metadata"
    , confirm = "Confirm"
    , unconfirm = "Unconfirm"
    , changeTagMode = "Change tag edit mode"
    , folderTab = "Folder"
    , folderNotOwnerWarning =
        """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
                      """
    , customFieldsTab = "Custom Fields"
    , dateTab = "Date"
    , dueDateTab = "Due Date"
    , correspondentTab = "Correspondent"
    , organization = "Organization"
    , person = "Person"
    , concerningTab = "Concerning"
    , equipment = "Equipment"
    , directionTab = "Direction"
    , nameTab = "Name"
    }
