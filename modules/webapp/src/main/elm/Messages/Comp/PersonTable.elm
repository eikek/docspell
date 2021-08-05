{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.PersonTable exposing
    ( Texts
    , de
    , gb
    )

import Data.PersonUse exposing (PersonUse)
import Messages.Basics
import Messages.Data.PersonUse


type alias Texts =
    { basics : Messages.Basics.Texts
    , address : String
    , contact : String
    , use : String
    , personUseLabel : PersonUse -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , address = "Address"
    , contact = "Contact"
    , use = "Use"
    , personUseLabel = Messages.Data.PersonUse.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , address = "Addresse"
    , contact = "Kontakt"
    , use = "Art"
    , personUseLabel = Messages.Data.PersonUse.de
    }
