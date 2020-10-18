module App.Data exposing
    ( Model
    , Msg(..)
    , checkPage
    , defaultPage
    , init
    )

import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.VersionInfo exposing (VersionInfo)
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Http
import Page exposing (Page(..))
import Page.CollectiveSettings.Data
import Page.Home.Data
import Page.ItemDetail.Data
import Page.Login.Data
import Page.ManageData.Data
import Page.NewInvite.Data
import Page.Queue.Data
import Page.Register.Data
import Page.Upload.Data
import Page.UserSettings.Data
import Url exposing (Url)


type alias Model =
    { flags : Flags
    , key : Key
    , page : Page
    , version : VersionInfo
    , homeModel : Page.Home.Data.Model
    , loginModel : Page.Login.Data.Model
    , manageDataModel : Page.ManageData.Data.Model
    , collSettingsModel : Page.CollectiveSettings.Data.Model
    , userSettingsModel : Page.UserSettings.Data.Model
    , queueModel : Page.Queue.Data.Model
    , registerModel : Page.Register.Data.Model
    , uploadModel : Page.Upload.Data.Model
    , newInviteModel : Page.NewInvite.Data.Model
    , itemDetailModel : Page.ItemDetail.Data.Model
    , navMenuOpen : Bool
    , subs : Sub Msg
    , uiSettings : UiSettings
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
    in
    ( { flags = flags
      , key = key
      , page = page
      , version = Api.Model.VersionInfo.empty
      , homeModel = Page.Home.Data.init flags
      , loginModel = Page.Login.Data.emptyModel
      , manageDataModel = mdm
      , collSettingsModel = csm
      , userSettingsModel = um
      , queueModel = Page.Queue.Data.emptyModel
      , registerModel = Page.Register.Data.emptyModel
      , uploadModel = Page.Upload.Data.emptyModel
      , newInviteModel = Page.NewInvite.Data.emptyModel
      , itemDetailModel = Page.ItemDetail.Data.emptyModel
      , navMenuOpen = False
      , subs = Sub.none
      , uiSettings = settings
      }
    , Cmd.batch
        [ Cmd.map UserSettingsMsg uc
        , Cmd.map ManageDataMsg mdc
        , Cmd.map CollSettingsMsg csc
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
    | HomeMsg Page.Home.Data.Msg
    | LoginMsg Page.Login.Data.Msg
    | ManageDataMsg Page.ManageData.Data.Msg
    | CollSettingsMsg Page.CollectiveSettings.Data.Msg
    | UserSettingsMsg Page.UserSettings.Data.Msg
    | QueueMsg Page.Queue.Data.Msg
    | RegisterMsg Page.Register.Data.Msg
    | UploadMsg Page.Upload.Data.Msg
    | NewInviteMsg Page.NewInvite.Data.Msg
    | ItemDetailMsg Page.ItemDetail.Data.Msg
    | Logout
    | LogoutResp (Result Http.Error ())
    | SessionCheckResp (Result Http.Error AuthResult)
    | ToggleNavMenu
    | GetUiSettings UiSettings


isSignedIn : Flags -> Bool
isSignedIn flags =
    flags.account
        |> Maybe.map .success
        |> Maybe.withDefault False


checkPage : Flags -> Page -> Page
checkPage flags page =
    if Page.isSecured page && isSignedIn flags then
        page

    else if Page.isOpen page then
        page

    else
        Page.loginPage page


defaultPage : Flags -> Page
defaultPage flags =
    if isSignedIn flags then
        HomePage

    else
        LoginPage Nothing
