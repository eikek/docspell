{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Dashboard exposing (Texts, de, gb)

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.BookmarkChooser
import Messages.Comp.DashboardManage
import Messages.Comp.DashboardView
import Messages.Comp.EquipmentManage
import Messages.Comp.FolderManage
import Messages.Comp.NotificationHookManage
import Messages.Comp.OrgManage
import Messages.Comp.PeriodicQueryTaskManage
import Messages.Comp.PersonManage
import Messages.Comp.ShareManage
import Messages.Comp.SourceManage
import Messages.Comp.TagManage
import Messages.Comp.UploadForm
import Messages.Data.AccountScope
import Messages.Page.DefaultDashboard


type alias Texts =
    { basics : Messages.Basics.Texts
    , bookmarkChooser : Messages.Comp.BookmarkChooser.Texts
    , notificationHookManage : Messages.Comp.NotificationHookManage.Texts
    , periodicQueryManage : Messages.Comp.PeriodicQueryTaskManage.Texts
    , sourceManage : Messages.Comp.SourceManage.Texts
    , shareManage : Messages.Comp.ShareManage.Texts
    , organizationManage : Messages.Comp.OrgManage.Texts
    , personManage : Messages.Comp.PersonManage.Texts
    , equipManage : Messages.Comp.EquipmentManage.Texts
    , tagManage : Messages.Comp.TagManage.Texts
    , folderManage : Messages.Comp.FolderManage.Texts
    , uploadForm : Messages.Comp.UploadForm.Texts
    , dashboard : Messages.Comp.DashboardView.Texts
    , dashboardManage : Messages.Comp.DashboardManage.Texts
    , defaultDashboard : Messages.Page.DefaultDashboard.Texts
    , accountScope : Messages.Data.AccountScope.Texts
    , manage : String
    , dashboardLink : String
    , bookmarks : String
    , misc : String
    , settings : String
    , documentation : String
    , uploadFiles : String
    , editDashboard : String
    , dashboards : String
    , predefinedMessage : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , bookmarkChooser = Messages.Comp.BookmarkChooser.gb
    , notificationHookManage = Messages.Comp.NotificationHookManage.gb
    , periodicQueryManage = Messages.Comp.PeriodicQueryTaskManage.gb tz
    , sourceManage = Messages.Comp.SourceManage.gb
    , shareManage = Messages.Comp.ShareManage.gb tz
    , organizationManage = Messages.Comp.OrgManage.gb
    , personManage = Messages.Comp.PersonManage.gb
    , equipManage = Messages.Comp.EquipmentManage.gb
    , tagManage = Messages.Comp.TagManage.gb
    , folderManage = Messages.Comp.FolderManage.gb tz
    , uploadForm = Messages.Comp.UploadForm.gb
    , dashboard = Messages.Comp.DashboardView.gb tz
    , dashboardManage = Messages.Comp.DashboardManage.gb
    , defaultDashboard = Messages.Page.DefaultDashboard.gb
    , accountScope = Messages.Data.AccountScope.gb
    , manage = "Manage"
    , dashboardLink = "Dashboard"
    , bookmarks = "Bookmarks"
    , misc = "Misc"
    , settings = "Settings"
    , documentation = "Documentation"
    , uploadFiles = "Upload documents"
    , editDashboard = "Edit Dashboard"
    , dashboards = "Dashboards"
    , predefinedMessage = "This dashboard is predefined one that cannot be deleted. It is replaced with the first one you save."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , bookmarkChooser = Messages.Comp.BookmarkChooser.de
    , notificationHookManage = Messages.Comp.NotificationHookManage.de
    , periodicQueryManage = Messages.Comp.PeriodicQueryTaskManage.de tz
    , sourceManage = Messages.Comp.SourceManage.de
    , shareManage = Messages.Comp.ShareManage.de tz
    , organizationManage = Messages.Comp.OrgManage.de
    , personManage = Messages.Comp.PersonManage.de
    , equipManage = Messages.Comp.EquipmentManage.de
    , tagManage = Messages.Comp.TagManage.de
    , folderManage = Messages.Comp.FolderManage.de tz
    , uploadForm = Messages.Comp.UploadForm.de
    , dashboard = Messages.Comp.DashboardView.de tz
    , dashboardManage = Messages.Comp.DashboardManage.de
    , defaultDashboard = Messages.Page.DefaultDashboard.de
    , accountScope = Messages.Data.AccountScope.de
    , manage = "Verwalten"
    , dashboardLink = "Dashboard"
    , bookmarks = "Bookmarks"
    , misc = "Anderes"
    , settings = "Einstellungen"
    , documentation = "Dokumentation"
    , uploadFiles = "Dokumente hochladen"
    , editDashboard = "Dashboard ändern"
    , dashboards = "Dashboards"
    , predefinedMessage = "Dieses Dashboard ist vordefiniert und kann nicht entfernt werden. Es wird durch ein gespeichertes ersetzt."
    }
