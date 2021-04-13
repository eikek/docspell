module Messages.Comp.NotificationTable exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , summary : String
    , schedule : String
    , connection : String
    , recipients : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , summary = "Summary"
    , schedule = "Schedule"
    , connection = "Connection"
    , recipients = "Recipients"
    }
