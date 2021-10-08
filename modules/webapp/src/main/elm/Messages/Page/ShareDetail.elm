{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.ShareDetail exposing (..)

import Data.Fields exposing (Field)
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


gb : Texts
gb =
    { passwordForm = Messages.Comp.SharePasswordForm.gb
    , basics = Messages.Basics.gb
    , field = Messages.Data.Fields.gb
    , formatDateLong = Messages.DateFormat.formatDateLong English
    , formatDateShort = Messages.DateFormat.formatDateShort English
    , authFailed = "This share does not exist."
    , httpError = Messages.Comp.HttpError.gb
    , tagsAndFields = "Tags & Fields"
    , noName = "No name"
    , unconfirmed = "Unconfirmed"
    }


de : Texts
de =
    { passwordForm = Messages.Comp.SharePasswordForm.de
    , basics = Messages.Basics.de
    , field = Messages.Data.Fields.de
    , formatDateLong = Messages.DateFormat.formatDateLong German
    , formatDateShort = Messages.DateFormat.formatDateShort German
    , authFailed = "Diese Freigabe existiert nicht."
    , httpError = Messages.Comp.HttpError.de
    , tagsAndFields = "Tags & Felder"
    , noName = "Kein Name"
    , unconfirmed = "Nicht bestätigt"
    }
