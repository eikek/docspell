module Messages.Comp.ItemCard exposing
    ( Texts
    , de
    , gb
    )

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


de : Texts
de =
    { basics = Messages.Basics.de
    , dueOn = "Fällig am"
    , new = "Neu"
    , openAttachmentFile = "Öffne Anhang"
    , gotoDetail = "Gehe zur Detail-Ansicht"
    , cycleAttachments = "Gehe durch Anhänge"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.German
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.German
    , directionLabel = Messages.Data.Direction.de
    }
