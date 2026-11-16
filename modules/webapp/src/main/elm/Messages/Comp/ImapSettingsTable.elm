{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ImapSettingsTable exposing (Texts, de, fr, gb, pt)

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


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , hostPort = "Hôte/Port"
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , hostPort = "Host/Porta"
    }
