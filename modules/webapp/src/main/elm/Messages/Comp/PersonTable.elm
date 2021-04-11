module Messages.Comp.PersonTable exposing (Texts, gb)

import Data.PersonUse exposing (PersonUse)
import Messages.Basics
import Messages.Data.PersonUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , address : String
    , contact : String
    , use : String
    , personUseLabel : PersonUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , address = "Address"
    , contact = "Contact"
    , use = "Use"
    , personUseLabel = Messages.Data.PersonUse.gb
    }
