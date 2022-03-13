{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.CollectiveSettings exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
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


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , userManage = Messages.Comp.UserManage.gb tz
    , collectiveSettingsForm = Messages.Comp.CollectiveSettingsForm.gb tz
    , sourceManage = Messages.Comp.SourceManage.gb
    , shareManage = Messages.Comp.ShareManage.gb tz
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


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , userManage = Messages.Comp.UserManage.de tz
    , collectiveSettingsForm = Messages.Comp.CollectiveSettingsForm.de tz
    , sourceManage = Messages.Comp.SourceManage.de
    , shareManage = Messages.Comp.ShareManage.de tz
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


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , userManage = Messages.Comp.UserManage.fr tz
    , collectiveSettingsForm = Messages.Comp.CollectiveSettingsForm.fr tz
    , sourceManage = Messages.Comp.SourceManage.fr
    , shareManage = Messages.Comp.ShareManage.fr tz
    , httpError = Messages.Comp.HttpError.fr
    , collectiveSettings = "Paramètres de groupe"
    , insights = "Synthèse"
    , settings = "Configuration"
    , users = "Utilisateurs"
    , user = "Utilisateur"
    , collective = "Global"
    , size = "Taille"
    , items = "Documents"
    , submitSuccessful = "Configuration sauvegardée."
    }
