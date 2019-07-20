module App.Data exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Http
import Data.Flags exposing (Flags)
import Api.Model.VersionInfo exposing (VersionInfo)
import Api.Model.AuthResult exposing (AuthResult)
import Page exposing (Page(..))
import Page.Home.Data
import Page.Login.Data

type alias Model =
    { flags: Flags
    , key: Key
    , page: Page
    , version: VersionInfo
    , homeModel: Page.Home.Data.Model
    , loginModel: Page.Login.Data.Model
    }

init: Key -> Url -> Flags -> Model
init key url flags =
    let
        page = Page.fromUrl url |> Maybe.withDefault HomePage
    in
        { flags = flags
        , key = key
        , page = page
        , version = Api.Model.VersionInfo.empty
        , homeModel = Page.Home.Data.emptyModel
        , loginModel = Page.Login.Data.empty
        }

type Msg
    = NavRequest UrlRequest
    | NavChange Url
    | VersionResp (Result Http.Error VersionInfo)
    | HomeMsg Page.Home.Data.Msg
    | LoginMsg Page.Login.Data.Msg
    | Logout
    | LogoutResp (Result Http.Error ())
    | SessionCheckResp (Result Http.Error AuthResult)
    | SetPage Page
