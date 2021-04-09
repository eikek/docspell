module Messages.Comp.ImapSettingsTable exposing (..)


type alias Texts =
    { name : String
    , hostPort : String
    }


gb : Texts
gb =
    { name = "Name"
    , hostPort = "Host/Port"
    }
