module Messages.ScanMailboxTableComp exposing (..)


type alias Texts =
    { summary : String
    , connection : String
    , folders : String
    , receivedSince : String
    }


gb : Texts
gb =
    { summary = "Summary"
    , connection = "Connection"
    , folders = "Folders"
    , receivedSince = "Received Since"
    }
