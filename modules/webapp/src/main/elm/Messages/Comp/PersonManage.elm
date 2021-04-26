module Messages.Comp.PersonManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.PersonForm
import Messages.Comp.PersonTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , personForm : Messages.Comp.PersonForm.Texts
    , personTable : Messages.Comp.PersonTable.Texts
    , httpError : Http.Error -> String
    , newPerson : String
    , createNewPerson : String
    , reallyDeletePerson : String
    , deleteThisPerson : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , personForm = Messages.Comp.PersonForm.gb
    , personTable = Messages.Comp.PersonTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newPerson = "New Person"
    , createNewPerson = "Create a new person"
    , reallyDeletePerson = "Really delete this person?"
    , deleteThisPerson = "Delete this person"
    , correctFormErrors = "Please correct the errors in the form."
    }
