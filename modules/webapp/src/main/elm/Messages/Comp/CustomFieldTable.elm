module Messages.Comp.CustomFieldTable exposing (Texts, gb)

import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , nameLabel : String
    , format : String
    , usageCount : String
    , formatDateShort : Int -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , nameLabel = "Name/Label"
    , format = "Format"
    , usageCount = "#Usage"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.English
    }
