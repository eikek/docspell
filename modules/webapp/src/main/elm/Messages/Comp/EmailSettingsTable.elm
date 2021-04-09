module Messages.Comp.EmailSettingsTable exposing (..)


type alias Texts =
    { name : String
    , hostPort : String
    , from : String
    }


gb : Texts
gb =
    { name = "Name"
    , hostPort = "Host/Port"
    , from = "From"
    }
