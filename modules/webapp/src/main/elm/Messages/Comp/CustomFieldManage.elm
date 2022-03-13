{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CustomFieldManage exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.CustomFieldForm
import Messages.Comp.CustomFieldTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , fieldForm : Messages.Comp.CustomFieldForm.Texts
    , fieldTable : Messages.Comp.CustomFieldTable.Texts
    , addCustomField : String
    , newCustomField : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , fieldForm = Messages.Comp.CustomFieldForm.gb
    , fieldTable = Messages.Comp.CustomFieldTable.gb tz
    , addCustomField = "Add a new custom field"
    , newCustomField = "New custom field"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , fieldForm = Messages.Comp.CustomFieldForm.de
    , fieldTable = Messages.Comp.CustomFieldTable.de tz
    , addCustomField = "Ein neues Benutzerfeld anlegen"
    , newCustomField = "Neues Benutzerfeld"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , fieldForm = Messages.Comp.CustomFieldForm.fr
    , fieldTable = Messages.Comp.CustomFieldTable.fr tz
    , addCustomField = "Ajouter un champs personnalisé"
    , newCustomField = "Nouveau champs personnalisé"
    }
