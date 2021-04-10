module Messages.Comp.FolderTable exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , memberCount : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , memberCount = "#Member"
    }
