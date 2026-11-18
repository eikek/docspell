{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.EmailSettingsTable exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , hostPort : String
    , from : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , hostPort = "Host/Port"
    , from = "From"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , hostPort = "Server/Port"
    , from = "Absender"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , hostPort = "Hôte/Port"
    , from = "De"
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , hostPort = "Host/Porta"
    , from = "De"
    }
