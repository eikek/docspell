{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Data exposing
    ( Content(..)
    , Model
    , Msg(..)
    , SideMenuModel
    , init
    , reloadDashboard
    , reloadUiSettings
    )

import Api
import Comp.BookmarkChooser
import Comp.DashboardView
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.NotificationHookManage
import Comp.OrgManage
import Comp.PeriodicQueryTaskManage
import Comp.PersonManage
import Comp.ShareManage
import Comp.SourceManage
import Comp.TagManage
import Data.Bookmarks exposing (AllBookmarks)
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)


type alias SideMenuModel =
    { bookmarkChooser : Comp.BookmarkChooser.Model
    }


type alias Model =
    { sideMenu : SideMenuModel
    , content : Content
    }


init : Flags -> Dashboard -> ( Model, Cmd Msg )
init flags db =
    let
        ( dm, dc ) =
            Comp.DashboardView.init flags db
    in
    ( { sideMenu =
            { bookmarkChooser = Comp.BookmarkChooser.init Data.Bookmarks.empty
            }
      , content = Home dm
      }
    , Cmd.batch
        [ initCmd flags
        , Cmd.map DashboardMsg dc
        ]
    )


initCmd : Flags -> Cmd Msg
initCmd flags =
    let
        ignoreBookmarkError r =
            Result.withDefault Data.Bookmarks.empty r
                |> GetBookmarksResp
    in
    Api.getBookmarks flags ignoreBookmarkError


reloadDashboard : Msg
reloadDashboard =
    InitDashboard


reloadUiSettings : Msg
reloadUiSettings =
    InitDashboard


type Msg
    = GetBookmarksResp AllBookmarks
    | BookmarkMsg Comp.BookmarkChooser.Msg
    | NotificationHookMsg Comp.NotificationHookManage.Msg
    | PeriodicQueryMsg Comp.PeriodicQueryTaskManage.Msg
    | SourceMsg Comp.SourceManage.Msg
    | ShareMsg Comp.ShareManage.Msg
    | OrganizationMsg Comp.OrgManage.Msg
    | PersonMsg Comp.PersonManage.Msg
    | EquipmentMsg Comp.EquipmentManage.Msg
    | TagMsg Comp.TagManage.Msg
    | FolderMsg Comp.FolderManage.Msg
    | DashboardMsg Comp.DashboardView.Msg
    | InitNotificationHook
    | InitDashboard
    | InitPeriodicQuery
    | InitSource
    | InitShare
    | InitOrganization
    | InitPerson
    | InitEquipment
    | InitTags
    | InitFolder


type Content
    = Home Comp.DashboardView.Model
    | Webhook Comp.NotificationHookManage.Model
    | PeriodicQuery Comp.PeriodicQueryTaskManage.Model
    | Source Comp.SourceManage.Model
    | Share Comp.ShareManage.Model
    | Organization Comp.OrgManage.Model
    | Person Comp.PersonManage.Model
    | Equipment Comp.EquipmentManage.Model
    | Tags Comp.TagManage.Model
    | Folder Comp.FolderManage.Model
