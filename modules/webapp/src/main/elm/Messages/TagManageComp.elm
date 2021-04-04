module Messages.TagManageComp exposing (..)

import Messages.Basics
import Messages.TagFormComp
import Messages.TagTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagTable : Messages.TagTableComp.Texts
    , tagForm : Messages.TagFormComp.Texts
    , createNewTag : String
    , newTag : String
    , reallyDeleteTag : String
    , deleteThisTag : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagTable = Messages.TagTableComp.gb
    , tagForm = Messages.TagFormComp.gb
    , createNewTag = "Create a new tag"
    , newTag = "New Tag"
    , reallyDeleteTag = "Really delete this tag?"
    , deleteThisTag = "Delete this tag"
    }
