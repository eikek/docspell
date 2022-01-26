module Messages.Page.Dashboard exposing (Texts, de, gb)

import Messages.Comp.BookmarkChooser
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
import Messages.Page.DefaultDashboard


type alias Texts =
    { bookmarkChooser : Messages.Comp.BookmarkChooser.Texts
    , notificationHookManage : Messages.Comp.NotificationHookManage.Texts
    , periodicQueryManage : Messages.Comp.PeriodicQueryTaskManage.Texts
    , sourceManage : Messages.Comp.SourceManage.Texts
    , shareManage : Messages.Comp.ShareManage.Texts
    , organizationManage : Messages.Comp.OrgManage.Texts
    , personManage : Messages.Comp.PersonManage.Texts
    , equipManage : Messages.Comp.EquipmentManage.Texts
    , tagManage : Messages.Comp.TagManage.Texts
    , folderManage : Messages.Comp.FolderManage.Texts
    , dashboard : Messages.Comp.DashboardView.Texts
    , defaultDashboard : Messages.Page.DefaultDashboard.Texts
    }


gb : Texts
gb =
    { bookmarkChooser = Messages.Comp.BookmarkChooser.gb
    , notificationHookManage = Messages.Comp.NotificationHookManage.gb
    , periodicQueryManage = Messages.Comp.PeriodicQueryTaskManage.gb
    , sourceManage = Messages.Comp.SourceManage.gb
    , shareManage = Messages.Comp.ShareManage.gb
    , organizationManage = Messages.Comp.OrgManage.gb
    , personManage = Messages.Comp.PersonManage.gb
    , equipManage = Messages.Comp.EquipmentManage.gb
    , tagManage = Messages.Comp.TagManage.gb
    , folderManage = Messages.Comp.FolderManage.gb
    , dashboard = Messages.Comp.DashboardView.gb
    , defaultDashboard = Messages.Page.DefaultDashboard.gb
    }


de : Texts
de =
    { bookmarkChooser = Messages.Comp.BookmarkChooser.de
    , notificationHookManage = Messages.Comp.NotificationHookManage.de
    , periodicQueryManage = Messages.Comp.PeriodicQueryTaskManage.de
    , sourceManage = Messages.Comp.SourceManage.de
    , shareManage = Messages.Comp.ShareManage.de
    , organizationManage = Messages.Comp.OrgManage.de
    , personManage = Messages.Comp.PersonManage.de
    , equipManage = Messages.Comp.EquipmentManage.de
    , tagManage = Messages.Comp.TagManage.de
    , folderManage = Messages.Comp.FolderManage.de
    , dashboard = Messages.Comp.DashboardView.de
    , defaultDashboard = Messages.Page.DefaultDashboard.de
    }
