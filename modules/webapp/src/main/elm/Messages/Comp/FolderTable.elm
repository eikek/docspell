module Messages.Comp.FolderTable exposing (Texts, gb)

import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , memberCount : String
    , formatDateShort : Int -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , memberCount = "#Member"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.English
    }
