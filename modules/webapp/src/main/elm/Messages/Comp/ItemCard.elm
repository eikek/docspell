module Messages.Comp.ItemCard exposing (Texts, gb)

import Data.Direction exposing (Direction)
import Messages.Basics
import Messages.Data.Direction
import Messages.DateFormat
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , dueOn : String
    , new : String
    , openAttachmentFile : String
    , gotoDetail : String
    , cycleAttachments : String
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    , directionLabel : Direction -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , dueOn = "Due on"
    , new = "New"
    , openAttachmentFile = "Open attachment file"
    , gotoDetail = "Go to detail view"
    , cycleAttachments = "Cycle attachments"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.English
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.English
    , directionLabel = Messages.Data.Direction.gb
    }
