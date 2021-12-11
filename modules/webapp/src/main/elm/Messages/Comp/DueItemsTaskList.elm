{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DueItemsTaskList exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , summary : String
    , schedule : String
    , connection : String
    , recipients : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , summary = "Summary"
    , schedule = "Schedule"
    , connection = "Connection"
    , recipients = "Recipients"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , summary = "Kurzbeschreibung"
    , schedule = "Zeitplan"
    , connection = "Verbindung"
    , recipients = "Empfänger"
    }
