module Messages.Comp.EmailSettingsTable exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , hostPort : String
    , from : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , hostPort = "Host/Port"
    , from = "From"
    }
