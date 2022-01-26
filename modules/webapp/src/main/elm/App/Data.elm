{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module App.Data exposing
    ( Model
    , Msg(..)
    , defaultPage
    , getUiLanguage
    , init
    )

import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.VersionInfo exposing (VersionInfo)
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Data.ServerEvent exposing (ServerEvent)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)
import Data.UiTheme exposing (UiTheme)
import Http
import Messages
import Messages.UiLanguage exposing (UiLanguage)
import Page exposing (Page(..))
import Page.CollectiveSettings.Data
import Page.Dashboard.Data
import Page.Dashboard.DefaultDashboard
import Page.ItemDetail.Data
import Page.Login.Data
import Page.ManageData.Data
import Page.NewInvite.Data
import Page.Queue.Data
import Page.Register.Data
import Page.Search.Data
import Page.Share.Data
import Page.ShareDetail.Data
import Page.Upload.Data
import Page.UserSettings.Data
import Url exposing (Url)


type alias Model =
    { flags : Flags
    , key : Key
    , page : Page
    , version : VersionInfo
    , searchModel : Page.Search.Data.Model
    , loginModel : Page.Login.Data.Model
    , manageDataModel : Page.ManageData.Data.Model
    , collSettingsModel : Page.CollectiveSettings.Data.Model
    , userSettingsModel : Page.UserSettings.Data.Model
    , queueModel : Page.Queue.Data.Model
    , registerModel : Page.Register.Data.Model
    , uploadModel : Page.Upload.Data.Model
    , newInviteModel : Page.NewInvite.Data.Model
    , itemDetailModel : Page.ItemDetail.Data.Model
    , shareModel : Page.Share.Data.Model
    , shareDetailModel : Page.ShareDetail.Data.Model
    , dashboardModel : Page.Dashboard.Data.Model
    , navMenuOpen : Bool
    , userMenuOpen : Bool
    , subs : Sub Msg
    , uiSettings : UiSettings
    , sidebarVisible : Bool
    , anonymousTheme : UiTheme
    , anonymousUiLang : UiLanguage
    , langMenuOpen : Bool
    , showNewItemsArrived : Bool
    , jobsWaiting : Int
    }


init : Key -> Url -> Flags -> UiSettings -> ( Model, Cmd Msg )
init key url flags_ settings =
    let
        flags =
            initBaseUrl url flags_

        page =
            Page.fromUrl url
                |> Maybe.withDefault (defaultPage flags)

        ( um, uc ) =
            Page.UserSettings.Data.init flags settings

        ( mdm, mdc ) =
            Page.ManageData.Data.init flags

        ( csm, csc ) =
            Page.CollectiveSettings.Data.init flags

        ( loginm, loginc ) =
            Page.Login.Data.init flags (Page.loginPageReferrer page)

        ( shm, shc ) =
            Page.Share.Data.init (Page.pageShareId page) flags

        ( sdm, sdc ) =
            Page.ShareDetail.Data.init (Page.pageShareDetail page) flags

        ( dbm, dbc ) =
            Page.Dashboard.Data.init flags
                (Page.Dashboard.DefaultDashboard.getDefaultDashboard flags settings)

        searchViewMode =
            if settings.searchMenuVisible then
                Page.Search.Data.SearchView

            else
                Page.Search.Data.SimpleView
    in
    ( { flags = flags
      , key = key
      , page = page
      , version = Api.Model.VersionInfo.empty
      , searchModel = Page.Search.Data.init flags searchViewMode
      , loginModel = loginm
      , manageDataModel = mdm
      , collSettingsModel = csm
      , userSettingsModel = um
      , queueModel = Page.Queue.Data.emptyModel
      , registerModel = Page.Register.Data.emptyModel
      , uploadModel = Page.Upload.Data.emptyModel
      , newInviteModel = Page.NewInvite.Data.emptyModel
      , itemDetailModel = Page.ItemDetail.Data.emptyModel
      , shareModel = shm
      , shareDetailModel = sdm
      , dashboardModel = dbm
      , navMenuOpen = False
      , userMenuOpen = False
      , subs = Sub.none
      , uiSettings = settings
      , sidebarVisible = flags.innerWidth > 768 && settings.sideMenuVisible
      , anonymousTheme = Data.UiTheme.Light
      , anonymousUiLang = Messages.UiLanguage.English
      , langMenuOpen = False
      , showNewItemsArrived = False
      , jobsWaiting = 0
      }
    , Cmd.batch
        [ Cmd.map DashboardMsg dbc
        , Cmd.map UserSettingsMsg uc
        , Cmd.map ManageDataMsg mdc
        , Cmd.map CollSettingsMsg csc
        , Cmd.map LoginMsg loginc
        , Cmd.map ShareMsg shc
        , Cmd.map ShareDetailMsg sdc
        ]
    )


initBaseUrl : Url -> Flags -> Flags
initBaseUrl url flags_ =
    let
        cfg =
            flags_.config

        baseUrl =
            if cfg.baseUrl == "" then
                Url.toString
                    { url
                        | path = ""
                        , query = Nothing
                        , fragment = Nothing
                    }

            else
                cfg.baseUrl

        cfgNew =
            { cfg | baseUrl = baseUrl }
    in
    { flags_ | config = cfgNew }


type Msg
    = NavRequest UrlRequest
    | NavChange Url
    | VersionResp (Result Http.Error VersionInfo)
    | SearchMsg Page.Search.Data.Msg
    | LoginMsg Page.Login.Data.Msg
    | ManageDataMsg Page.ManageData.Data.Msg
    | CollSettingsMsg Page.CollectiveSettings.Data.Msg
    | UserSettingsMsg Page.UserSettings.Data.Msg
    | QueueMsg Page.Queue.Data.Msg
    | RegisterMsg Page.Register.Data.Msg
    | UploadMsg Page.Upload.Data.Msg
    | NewInviteMsg Page.NewInvite.Data.Msg
    | ItemDetailMsg Page.ItemDetail.Data.Msg
    | ShareMsg Page.Share.Data.Msg
    | ShareDetailMsg Page.ShareDetail.Data.Msg
    | DashboardMsg Page.Dashboard.Data.Msg
    | Logout
    | LogoutResp (Result Http.Error ())
    | SessionCheckResp (Result Http.Error AuthResult)
    | ToggleNavMenu
    | ToggleUserMenu
    | GetUiSettings (Result Http.Error UiSettings)
    | ToggleSidebar
    | ToggleDarkMode
    | ToggleLangMenu
    | SetLanguage UiLanguage
    | ClientSettingsSaveResp UiSettings (Result Http.Error BasicResult)
    | ReceiveBrowserSettings StoredUiSettings
    | ReceiveWsMessage (Result String ServerEvent)
    | ToggleShowNewItemsArrived


defaultPage : Flags -> Page
defaultPage _ =
    DashboardPage


getUiLanguage : Model -> UiLanguage
getUiLanguage model =
    Data.UiSettings.getUiLanguage model.flags model.uiSettings model.anonymousUiLang
