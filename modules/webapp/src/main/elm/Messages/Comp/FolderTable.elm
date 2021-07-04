{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.FolderTable exposing
    ( Texts
    , de
    , gb
    )

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


de : Texts
de =
    { basics = Messages.Basics.de
    , memberCount = "#Mitglieder"
    , formatDateShort = DF.formatDateShort Messages.UiLanguage.German
    }
