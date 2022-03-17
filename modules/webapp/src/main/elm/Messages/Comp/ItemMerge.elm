{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemMerge exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.DateFormat
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , title : String
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    , cancelView : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , title = "Merge Items"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.English tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.English tz
    , cancelView = "Cancel"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , title = "Dokumente zusammenführen"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.German tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.German tz
    , cancelView = "Abbrechen"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , title = "Fusionner des documents"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.French tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.French tz
    , cancelView = "Annuler"
    }
