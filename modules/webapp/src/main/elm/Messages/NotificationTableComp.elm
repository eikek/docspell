module Messages.NotificationTableComp exposing (..)


type alias Texts =
    { summary : String
    , schedule : String
    , connection : String
    , recipients : String
    }


gb : Texts
gb =
    { summary = "Summary"
    , schedule = "Schedule"
    , connection = "Connection"
    , recipients = "Recipients"
    }
