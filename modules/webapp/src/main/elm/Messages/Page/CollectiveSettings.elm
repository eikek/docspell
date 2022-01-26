{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.CollectiveSettings exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.CollectiveSettingsForm
import Messages.Comp.HttpError
import Messages.Comp.ShareManage
import Messages.Comp.SourceManage
import Messages.Comp.UserManage


type alias Texts =
    { basics : Messages.Basics.Texts
    , userManage : Messages.Comp.UserManage.Texts
    , collectiveSettingsForm : Messages.Comp.CollectiveSettingsForm.Texts
    , sourceManage : Messages.Comp.SourceManage.Texts
    , shareManage : Messages.Comp.ShareManage.Texts
    , httpError : Http.Error -> String
    , collectiveSettings : String
    , insights : String
    , settings : String
    , users : String
    , user : String
    , collective : String
    , size : String
    , items : String
    , submitSuccessful : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , userManage = Messages.Comp.UserManage.gb
    , collectiveSettingsForm = Messages.Comp.CollectiveSettingsForm.gb
    , sourceManage = Messages.Comp.SourceManage.gb
    , shareManage = Messages.Comp.ShareManage.gb
    , httpError = Messages.Comp.HttpError.gb
    , collectiveSettings = "Collective Settings"
    , insights = "Insights"
    , settings = "Settings"
    , users = "Users"
    , user = "User"
    , collective = "Collective"
    , size = "Size"
    , items = "Items"
    , submitSuccessful = "Settings saved."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , userManage = Messages.Comp.UserManage.de
    , collectiveSettingsForm = Messages.Comp.CollectiveSettingsForm.de
    , sourceManage = Messages.Comp.SourceManage.de
    , shareManage = Messages.Comp.ShareManage.de
    , httpError = Messages.Comp.HttpError.de
    , collectiveSettings = "Kollektiveinstellungen"
    , insights = "Statistiken"
    , settings = "Einstellungen"
    , users = "Benutzer"
    , user = "Benutzer"
    , collective = "Kollektiv"
    , size = "Größe"
    , items = "Dokumente"
    , submitSuccessful = "Einstellungen gespeichert."
    }
