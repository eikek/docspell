{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Data exposing
    ( Content(..)
    , Model
    , Msg(..)
    , PageError(..)
    , SideMenuModel
    , init
    , isDashboardDefault
    , isDashboardVisible
    , isHomeContent
    , reloadDashboardData
    , reloadUiSettings
    )

import Api
import Comp.BookmarkChooser
import Comp.DashboardManage
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
import Comp.UploadForm
import Data.Bookmarks exposing (AllBookmarks)
import Data.Dashboard exposing (Dashboard)
import Data.Dashboards exposing (AllDashboards)
import Data.Flags exposing (Flags)
import Http


type alias SideMenuModel =
    { bookmarkChooser : Comp.BookmarkChooser.Model
    }


type alias Model =
    { sideMenu : SideMenuModel
    , content : Content
    , pageError : Maybe PageError
    , dashboards : AllDashboards
    , isPredefined : Bool
    }


type Msg
    = GetBookmarksResp AllBookmarks
    | GetAllDashboardsResp (Maybe Msg) (Result Http.Error AllDashboards)
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
    | UploadMsg Comp.UploadForm.Msg
    | DashboardMsg Comp.DashboardView.Msg
    | DashboardManageMsg Comp.DashboardManage.Msg
    | InitNotificationHook
    | InitPeriodicQuery
    | InitSource
    | InitShare
    | InitOrganization
    | InitPerson
    | InitEquipment
    | InitTags
    | InitFolder
    | InitUpload
    | InitEditDashboard
    | ReloadDashboardData
    | HardReloadDashboard
    | SetDashboard Dashboard
    | SetDashboardByName String
    | SetDefaultDashboard


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( dm, dc ) =
            Comp.DashboardView.init flags Data.Dashboard.empty
    in
    ( { sideMenu =
            { bookmarkChooser = Comp.BookmarkChooser.init Data.Bookmarks.empty
            }
      , content = Home dm
      , pageError = Nothing
      , dashboards = Data.Dashboards.emptyAll
      , isPredefined = True
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
    Cmd.batch
        [ Api.getBookmarks flags ignoreBookmarkError
        , Api.getAllDashboards flags (GetAllDashboardsResp (Just SetDefaultDashboard))
        ]


reloadDashboardData : Msg
reloadDashboardData =
    ReloadDashboardData


reloadUiSettings : Msg
reloadUiSettings =
    HardReloadDashboard



--- Content


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
    | Upload Comp.UploadForm.Model
    | Edit Comp.DashboardManage.Model


isHomeContent : Content -> Bool
isHomeContent cnt =
    case cnt of
        Home _ ->
            True

        _ ->
            False


isDashboardVisible : Model -> String -> Bool
isDashboardVisible model name =
    case model.content of
        Home m ->
            m.dashboard.name == name

        Edit m ->
            m.initData.dashboard.name == name

        _ ->
            False


isDashboardDefault : Model -> String -> Bool
isDashboardDefault model name =
    Data.Dashboards.isDefaultAll name model.dashboards



--- Errors


type PageError
    = PageErrorHttp Http.Error
    | PageErrorNoDashboard
    | PageErrorInvalid String
