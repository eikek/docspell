module Messages.Comp.ScanMailboxTable exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , summary : String
    , connection : String
    , folders : String
    , receivedSince : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , summary = "Summary"
    , connection = "Connection"
    , folders = "Folders"
    , receivedSince = "Received Since"
    }
