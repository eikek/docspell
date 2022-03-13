{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.ShareDetail exposing (..)

import Data.Fields exposing (Field)
import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.SharePasswordForm
import Messages.Data.Fields
import Messages.DateFormat
import Messages.UiLanguage exposing (UiLanguage(..))


type alias Texts =
    { passwordForm : Messages.Comp.SharePasswordForm.Texts
    , basics : Messages.Basics.Texts
    , field : Field -> String
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    , httpError : Http.Error -> String
    , authFailed : String
    , tagsAndFields : String
    , noName : String
    , unconfirmed : String
    }


gb : TimeZone -> Texts
gb tz =
    { passwordForm = Messages.Comp.SharePasswordForm.gb
    , basics = Messages.Basics.gb
    , field = Messages.Data.Fields.gb
    , formatDateLong = Messages.DateFormat.formatDateLong English tz
    , formatDateShort = Messages.DateFormat.formatDateShort English tz
    , authFailed = "This share does not exist."
    , httpError = Messages.Comp.HttpError.gb
    , tagsAndFields = "Tags & Fields"
    , noName = "No name"
    , unconfirmed = "Unconfirmed"
    }


de : TimeZone -> Texts
de tz =
    { passwordForm = Messages.Comp.SharePasswordForm.de
    , basics = Messages.Basics.de
    , field = Messages.Data.Fields.de
    , formatDateLong = Messages.DateFormat.formatDateLong German tz
    , formatDateShort = Messages.DateFormat.formatDateShort German tz
    , authFailed = "Diese Freigabe existiert nicht."
    , httpError = Messages.Comp.HttpError.de
    , tagsAndFields = "Tags & Felder"
    , noName = "Kein Name"
    , unconfirmed = "Nicht bestätigt"
    }


fr : TimeZone -> Texts
fr tz =
    { passwordForm = Messages.Comp.SharePasswordForm.fr
    , basics = Messages.Basics.fr
    , field = Messages.Data.Fields.fr
    , formatDateLong = Messages.DateFormat.formatDateLong French tz
    , formatDateShort = Messages.DateFormat.formatDateShort French tz
    , authFailed = "Ce partage n'existe pas."
    , httpError = Messages.Comp.HttpError.fr
    , tagsAndFields = "Tags & champs"
    , noName = "Aucun nom"
    , unconfirmed = "Non validé"
    }
