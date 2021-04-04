module Messages.ImapSettingsTableComp exposing (..)


type alias Texts =
    { name : String
    , hostPort : String
    }


gb : Texts
gb =
    { name = "Name"
    , hostPort = "Host/Port"
    }
