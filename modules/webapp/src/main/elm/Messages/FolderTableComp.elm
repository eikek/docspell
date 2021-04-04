module Messages.FolderTableComp exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , name : String
    , memberCount : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , name = "Name"
    , memberCount = "#Member"
    }
