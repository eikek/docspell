{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.EmptyTrashForm exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.CalEventInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , schedule : String
    , minAge : String
    , minAgeInfo : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb tz
    , schedule = "Schedule"
    , minAge = "Minimum Age (Days)"
    , minAgeInfo = "The minimum age in days of an items to be removed. The last-update time is used."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de tz
    , schedule = "Zeitplan"
    , minAge = "Mindestalter (Tage)"
    , minAgeInfo = "Das Mindestalter (in Tagen) der Dokumente, die gelöscht werden. Es wird das Datum der letzten Veränderung verwendet."
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , calEventInput = Messages.Comp.CalEventInput.fr tz
    , schedule = "Programmation"
    , minAge = "Durée minimum (jours)"
    , minAgeInfo = "Durée minimum en jours avant qu'un document soit supprimé. L'heure de la dernière mise à jour est utilisée."
    }
