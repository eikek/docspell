module Messages.Comp.PersonManage exposing (..)

import Messages.Basics
import Messages.Comp.PersonForm
import Messages.Comp.PersonTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , personForm : Messages.Comp.PersonForm.Texts
    , personTable : Messages.Comp.PersonTable.Texts
    , newPerson : String
    , createNewPerson : String
    , reallyDeletePerson : String
    , deleteThisPerson : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , personForm = Messages.Comp.PersonForm.gb
    , personTable = Messages.Comp.PersonTable.gb
    , newPerson = "New Person"
    , createNewPerson = "Create a new person"
    , reallyDeletePerson = "Really delete this person?"
    , deleteThisPerson = "Delete this person"
    }
