module Messages.Comp.OrgTable exposing (Texts, gb)

import Data.OrgUse exposing (OrgUse)
import Messages.Basics
import Messages.Data.OrgUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , address : String
    , contact : String
    , orgUseLabel : OrgUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , address = "Address"
    , contact = "Contact"
    , orgUseLabel = Messages.Data.OrgUse.gb
    }
