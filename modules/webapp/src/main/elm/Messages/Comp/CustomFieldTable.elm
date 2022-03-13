{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CustomFieldTable exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
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


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , nameLabel = "Name/Label"
    , format = "Format"
    , usageCount = "#Usage"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.English tz
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , nameLabel = "Name/Label"
    , format = "Format"
    , usageCount = "#Nutzung"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.German tz
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , nameLabel = "Nom/Label"
    , format = "Format"
    , usageCount = "#Utilisations"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.French tz
    }
