{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.CustomFieldTable exposing
    ( Texts
    , de
    , gb
    )

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


de : Texts
de =
    { basics = Messages.Basics.de
    , nameLabel = "Name/Label"
    , format = "Format"
    , usageCount = "#Nutzung"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.German
    }
