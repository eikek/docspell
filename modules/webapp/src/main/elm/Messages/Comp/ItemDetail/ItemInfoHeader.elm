{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.ItemInfoHeader exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , itemDate : String
    , dueDate : String
    , source : String
    , new : String
    , formatDate : Int -> String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , itemDate = "Item Date"
    , dueDate = "Due Date"
    , source = "Source"
    , new = "New"
    , formatDate = DF.formatDateLong Messages.UiLanguage.English tz
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , itemDate = "Datum"
    , dueDate = "Fälligkeitsdatum"
    , source = "Quelle"
    , new = "Neu"
    , formatDate = DF.formatDateLong Messages.UiLanguage.German tz
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , itemDate = "Date du document"
    , dueDate = "Date d'échéance"
    , source = "Source"
    , new = "Nouveau"
    , formatDate = DF.formatDateLong Messages.UiLanguage.French tz
    }
