module Messages.PersonManageComp exposing (..)

import Messages.Basics
import Messages.PersonFormComp
import Messages.PersonTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , personForm : Messages.PersonFormComp.Texts
    , personTable : Messages.PersonTableComp.Texts
    , newPerson : String
    , createNewPerson : String
    , reallyDeletePerson : String
    , deleteThisPerson : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , personForm = Messages.PersonFormComp.gb
    , personTable = Messages.PersonTableComp.gb
    , newPerson = "New Person"
    , createNewPerson = "Create a new person"
    , reallyDeletePerson = "Really delete this person?"
    , deleteThisPerson = "Delete this person"
    }
