module Messages.Comp.SourceTable exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , abbrev : String
    , enabled : String
    , counter : String
    , priority : String
    , id : String
    , show : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , abbrev = "Abbrev"
    , enabled = "Enabled"
    , counter = "Counter"
    , priority = "Priority"
    , id = "Id"
    , show = "Show"
    }
