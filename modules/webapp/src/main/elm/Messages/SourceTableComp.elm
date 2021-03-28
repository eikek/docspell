module Messages.SourceTableComp exposing (..)


type alias Texts =
    { abbrev : String
    , enabled : String
    , counter : String
    , priority : String
    , id : String
    , show : String
    }


gb : Texts
gb =
    { abbrev = "Abbrev"
    , enabled = "Enabled"
    , counter = "Counter"
    , priority = "Priority"
    , id = "Id"
    , show = "Show"
    }
