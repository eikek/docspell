module Messages.Comp.FolderDetail exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , reallyDeleteThisFolder : String
    , autoOwnerInfo : String
    , modifyInfo : String
    , notOwnerInfo : String
    , members : String
    , addMember : String
    , add : String
    , removeMember : String
    , deleteThisFolder : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , reallyDeleteThisFolder = "Really delete this folder?"
    , autoOwnerInfo = "You are automatically set as owner of this new folder."
    , modifyInfo = "Modify this folder by changing the name or add/remove members."
    , notOwnerInfo = "You are not the owner of this folder and therefore are not allowed to edit it."
    , members = "Members"
    , addMember = "Add a new member"
    , add = "Add"
    , removeMember = "Remove this member"
    , deleteThisFolder = "Delete this folder"
    }
