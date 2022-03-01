{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.FolderTable exposing
    ( Texts
    , de
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , memberCount : String
    , formatDateShort : Int -> String
    , owner : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , memberCount = "#Member"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.English tz
    , owner = "Owner"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , memberCount = "#Mitglieder"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.German tz
    , owner = "Besitzer"
    }
