{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ShareForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , queryLabel : String
    , enabled : String
    , password : String
    , publishUntil : String
    , clearPassword : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , queryLabel = "Query"
    , enabled = "Enabled"
    , password = "Password"
    , publishUntil = "Publish Until"
    , clearPassword = "Remove password"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , queryLabel = "Abfrage"
    , enabled = "Aktiv"
    , password = "Passwort"
    , publishUntil = "Publiziert bis"
    , clearPassword = "Passwort entfernen"
    }
