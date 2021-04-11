module Messages.Comp.ItemCard exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , dueOn : String
    , new : String
    , openAttachmentFile : String
    , gotoDetail : String
    , cycleAttachments : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , dueOn = "Due on"
    , new = "New"
    , openAttachmentFile = "Open attachment file"
    , gotoDetail = "Go to detail view"
    , cycleAttachments = "Cycle attachments"
    }
