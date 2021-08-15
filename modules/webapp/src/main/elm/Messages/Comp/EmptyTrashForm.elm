{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.EmptyTrashForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics
import Messages.Comp.CalEventInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , schedule : String
    , minAge : String
    , minAgeInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb
    , schedule = "Schedule"
    , minAge = "Minimum Age (Days)"
    , minAgeInfo = "The minimum age in days of an items to be removed. The last-update time is used."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de
    , schedule = "Zeitplan"
    , minAge = "Mindestalter (Tage)"
    , minAgeInfo = "Das Mindestalter (in Tagen) der Dokumente, die gelöscht werden. Es wird das Datum der letzten Veränderung verwendet."
    }
