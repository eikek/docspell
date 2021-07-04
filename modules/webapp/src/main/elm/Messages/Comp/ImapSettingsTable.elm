{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.ImapSettingsTable exposing (Texts, de, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , hostPort : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , hostPort = "Host/Port"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , hostPort = "Server/Port"
    }
