module Messages.Comp.TagManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.TagForm
import Messages.Comp.TagTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagTable : Messages.Comp.TagTable.Texts
    , tagForm : Messages.Comp.TagForm.Texts
    , httpError : Http.Error -> String
    , createNewTag : String
    , newTag : String
    , reallyDeleteTag : String
    , deleteThisTag : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagTable = Messages.Comp.TagTable.gb
    , tagForm = Messages.Comp.TagForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , createNewTag = "Create a new tag"
    , newTag = "New Tag"
    , reallyDeleteTag = "Really delete this tag?"
    , deleteThisTag = "Delete this tag"
    , correctFormErrors = "Please correct the errors in the form."
    }
