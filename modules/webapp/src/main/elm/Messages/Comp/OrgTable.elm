{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.OrgTable exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.OrgUse exposing (OrgUse)
import Messages.Basics
import Messages.Data.OrgUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , address : String
    , contact : String
    , use : String
    , orgUseLabel : OrgUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , address = "Address"
    , contact = "Contact"
    , use = "Use"
    , orgUseLabel = Messages.Data.OrgUse.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , address = "Addresse"
    , contact = "Kontakt"
    , use = "Typ"
    , orgUseLabel = Messages.Data.OrgUse.de
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , address = "Adresse"
    , contact = "Contact"
    , use = "Utiliser"
    , orgUseLabel = Messages.Data.OrgUse.fr
    }
