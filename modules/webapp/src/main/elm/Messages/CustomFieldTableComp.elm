module Messages.CustomFieldTableComp exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , nameLabel : String
    , format : String
    , usageCount : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , nameLabel = "Name/Label"
    , format = "Format"
    , usageCount = "#Usage"
    }
