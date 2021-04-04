module Messages.OrgTableComp exposing (..)

import Data.OrgUse exposing (OrgUse)
import Messages.Basics
import Messages.OrgUseData


type alias Texts =
    { basics : Messages.Basics.Texts
    , name : String
    , address : String
    , contact : String
    , orgUseLabel : OrgUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , name = "Name"
    , address = "Address"
    , contact = "Contact"
    , orgUseLabel = Messages.OrgUseData.gb
    }
