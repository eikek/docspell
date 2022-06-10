{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Data exposing
    ( Mode(..)
    , Model
    , Msg(..)
    , PageError(..)
    , SearchBarMode(..)
    , TopContentModel(..)
    , init
    , initCmd
    , pageSizes
    )

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.SearchStats exposing (SearchStats)
import Api.Model.ShareSecret exposing (ShareSecret)
import Api.Model.ShareVerifyResult exposing (ShareVerifyResult)
import Comp.DownloadAll
import Comp.ItemCardList
import Comp.PowerSearchInput
import Comp.SearchMenu
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
import Data.ItemArrange exposing (ItemArrange)
import Data.UiSettings exposing (UiSettings)
import Http
import Page.Search.Data exposing (Msg(..))
import Set exposing (Set)
import Util.Html exposing (KeyCode)


type Mode
    = ModeInitial
    | ModePassword
    | ModeShare


type PageError
    = PageErrorNone
    | PageErrorHttp Http.Error
    | PageErrorAuthFail


type SearchBarMode
    = SearchBarNormal
    | SearchBarContent


type TopContentModel
    = TopContentHidden
    | TopContentDownload Comp.DownloadAll.Model


type alias Model =
    { mode : Mode
    , verifyResult : ShareVerifyResult
    , passwordModel : Comp.SharePasswordForm.Model
    , pageError : PageError
    , searchMenuModel : Comp.SearchMenu.Model
    , powerSearchInput : Comp.PowerSearchInput.Model
    , searchInProgress : Bool
    , itemListModel : Comp.ItemCardList.Model
    , initialized : Bool
    , contentSearch : Maybe String
    , searchMode : SearchBarMode
    , uiSettings : UiSettings
    , viewMode :
        { menuOpen : Bool
        , showGroups : Bool
        , arrange : ItemArrange
        , rowsOpen : Set String
        , pageSizeMenuOpen : Bool
        , pageSize : Int
        , offset : Int
        }
    , topContent : TopContentModel
    }


emptyModel : Flags -> Model
emptyModel flags =
    { mode = ModeInitial
    , verifyResult = Api.Model.ShareVerifyResult.empty
    , passwordModel = Comp.SharePasswordForm.init
    , pageError = PageErrorNone
    , searchMenuModel = Comp.SearchMenu.init flags
    , powerSearchInput = Comp.PowerSearchInput.init
    , searchInProgress = False
    , itemListModel = Comp.ItemCardList.init
    , initialized = False
    , contentSearch = Nothing
    , searchMode = SearchBarContent
    , uiSettings = Data.UiSettings.defaults
    , viewMode =
        { menuOpen = False
        , showGroups = True
        , arrange = Data.ItemArrange.Cards
        , rowsOpen = Set.empty
        , pageSizeMenuOpen = False
        , pageSize = pageSizes flags |> List.head |> Maybe.withDefault 20
        , offset = 0
        }
    , topContent = TopContentHidden
    }


init : Maybe String -> Flags -> ( Model, Cmd Msg )
init shareId flags =
    let
        em =
            emptyModel flags
    in
    case shareId of
        Just id ->
            ( { em | initialized = True }, Api.verifyShare flags (ShareSecret id Nothing) VerifyResp )

        Nothing ->
            ( em, Cmd.none )


initCmd : String -> Flags -> Cmd Msg
initCmd shareId flags =
    Api.verifyShare flags (ShareSecret shareId Nothing) VerifyResp


type Msg
    = VerifyResp (Result Http.Error ShareVerifyResult)
    | SearchResp (Result Http.Error ItemLightList)
    | AddSearchResp (Result Http.Error ItemLightList)
    | StatsResp Bool (Result Http.Error SearchStats)
    | UiSettingsResp (Result Http.Error UiSettings)
    | PasswordMsg Comp.SharePasswordForm.Msg
    | SearchMenuMsg Comp.SearchMenu.Msg
    | PowerSearchMsg Comp.PowerSearchInput.Msg
    | ResetSearch
    | ItemListMsg Comp.ItemCardList.Msg
    | ToggleSearchBar
    | SetContentSearch String
    | ContentSearchKey (Maybe KeyCode)
    | ToggleViewMenu
    | ToggleArrange ItemArrange
    | ToggleShowGroups
    | DownloadAllMsg Comp.DownloadAll.Msg
    | ToggleDownloadAll
    | TogglePageSizeMenu
    | SetPageSize Int
    | LoadNextPage


pageSizes : Flags -> List Int
pageSizes flags =
    let
        maxSize =
            flags.config.maxPageSize

        high =
            min maxSize 60 // 10 * 10

        low =
            20

        gen n res =
            if n > high then
                res

            else
                gen (n + low) (n :: res)
    in
    if maxSize <= low then
        [ maxSize ]

    else
        List.reverse (gen low [])
