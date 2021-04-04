module Messages.PersonTableComp exposing (..)

import Data.PersonUse exposing (PersonUse)
import Messages.Basics
import Messages.PersonUseData


type alias Texts =
    { basics : Messages.Basics.Texts
    , name : String
    , address : String
    , contact : String
    , personUseLabel : PersonUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , name = "Name"
    , address = "Address"
    , contact = "Contact"
    , personUseLabel = Messages.PersonUseData.gb
    }
