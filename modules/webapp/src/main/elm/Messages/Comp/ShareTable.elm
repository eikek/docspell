{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ShareTable exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , formatDateTime : Int -> String
    , active : String
    , publishUntil : String
    , user : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English
    , active = "Active"
    , publishUntil = "Publish Until"
    , user = "User"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German
    , active = "Aktiv"
    , publishUntil = "Publiziert bis"
    , user = "Benutzer"
    }
