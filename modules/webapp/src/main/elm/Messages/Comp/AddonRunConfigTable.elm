{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AddonRunConfigTable exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , enabled : String
    , trigger : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , enabled = "Enabled"
    , trigger = "Triggered"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , enabled = "Aktive"
    , trigger = "Auslöser"
    }



-- TODO translate-fr


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , enabled = "Enabled"
    , trigger = "Triggered"
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , enabled = "有効"
    , trigger = "トリガー済み"
    }
