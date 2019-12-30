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
    }


init : Key -> Url -> Flags -> Model
init key url flags =
    let
        page =
            Page.fromUrl url
                |> Maybe.withDefault (defaultPage flags)
    in
    { flags = flags
    , key = key
    , page = page
    , version = Api.Model.VersionInfo.empty
    , homeModel = Page.Home.Data.emptyModel
    , loginModel = Page.Login.Data.emptyModel
    , manageDataModel = Page.ManageData.Data.emptyModel
    , collSettingsModel = Page.CollectiveSettings.Data.emptyModel
    , userSettingsModel = Page.UserSettings.Data.emptyModel
    , queueModel = Page.Queue.Data.emptyModel
    , registerModel = Page.Register.Data.emptyModel
    , uploadModel = Page.Upload.Data.emptyModel
    , newInviteModel = Page.NewInvite.Data.emptyModel
    , itemDetailModel = Page.ItemDetail.Data.emptyModel
    , navMenuOpen = False
    , subs = Sub.none
    }


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
