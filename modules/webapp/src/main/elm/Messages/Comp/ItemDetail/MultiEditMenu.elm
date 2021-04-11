module Messages.Comp.ItemDetail.MultiEditMenu exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.CustomFieldMultiInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagModeAddInfo : String
    , tagModeRemoveInfo : String
    , tagModeReplaceInfo : String
    , chooseDirection : String
    , confirmUnconfirm : String
    , confirm : String
    , unconfirm : String
    , changeTagMode : String
    , folderNotOwnerWarning : String
    , dueDateTab : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagModeAddInfo = "Tags chosen here are *added* to all selected items."
    , tagModeRemoveInfo = "Tags chosen here are *removed* from all selected items."
    , tagModeReplaceInfo = "Tags chosen here *replace* those on selected items."
    , chooseDirection = "Choose a direction…"
    , confirmUnconfirm = "Confirm/Unconfirm item metadata"
    , confirm = "Confirm"
    , unconfirm = "Unconfirm"
    , changeTagMode = "Change tag edit mode"
    , folderNotOwnerWarning =
        """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
                      """
    , dueDateTab = "Due Date"
    }
