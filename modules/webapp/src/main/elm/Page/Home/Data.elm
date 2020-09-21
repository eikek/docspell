module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , SearchType(..)
    , defaultSearchType
    , doSearchCmd
    , init
    , itemNav
    , resultsBelowLimit
    , searchTypeString
    )

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemSearch
import Browser.Dom as Dom
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Http
import Throttle exposing (Throttle)
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD


type alias Model =
    { searchMenuModel : Comp.SearchMenu.Model
    , itemListModel : Comp.ItemCardList.Model
    , searchInProgress : Bool
    , menuCollapsed : Bool
    , searchOffset : Int
    , moreAvailable : Bool
    , moreInProgress : Bool
    , throttle : Throttle Msg
    , searchTypeDropdown : Comp.FixedDropdown.Model SearchType
    , searchType : SearchType
    , searchTypeForm : SearchType
    , contentOnlySearch : Maybe String
    , dragDropData : DD.DragDropData
    }


init : Flags -> Model
init flags =
    let
        searchTypeOptions =
            if flags.config.fullTextSearchEnabled then
                [ BasicSearch, ContentOnlySearch ]

            else
                [ BasicSearch ]
    in
    { searchMenuModel = Comp.SearchMenu.init
    , itemListModel = Comp.ItemCardList.init
    , searchInProgress = False
    , menuCollapsed = True
    , searchOffset = 0
    , moreAvailable = True
    , moreInProgress = False
    , throttle = Throttle.create 1
    , searchTypeDropdown =
        Comp.FixedDropdown.initMap searchTypeString
            searchTypeOptions
    , searchType = BasicSearch
    , searchTypeForm = defaultSearchType flags
    , contentOnlySearch = Nothing
    , dragDropData =
        DD.DragDropData DD.init Nothing
    }


defaultSearchType : Flags -> SearchType
defaultSearchType flags =
    if flags.config.fullTextSearchEnabled then
        ContentOnlySearch

    else
        BasicSearch


type Msg
    = Init
    | SearchMenuMsg Comp.SearchMenu.Msg
    | ResetSearch
    | ItemCardListMsg Comp.ItemCardList.Msg
    | ItemSearchResp (Result Http.Error ItemLightList)
    | ItemSearchAddResp (Result Http.Error ItemLightList)
    | DoSearch
    | ToggleSearchMenu
    | LoadMore
    | UpdateThrottle
    | SetBasicSearch String
    | SearchTypeMsg (Comp.FixedDropdown.Msg SearchType)
    | KeyUpMsg (Maybe KeyCode)
    | SetContentOnly String
    | ScrollResult (Result Dom.Error ())
    | ClearItemDetailId


type SearchType
    = BasicSearch
    | ContentSearch
    | ContentOnlySearch


searchTypeString : SearchType -> String
searchTypeString st =
    case st of
        BasicSearch ->
            "Names"

        ContentSearch ->
            "Contents"

        ContentOnlySearch ->
            "Contents Only"


itemNav : String -> Model -> ItemNav
itemNav id model =
    let
        prev =
            Comp.ItemCardList.prevItem model.itemListModel id

        next =
            Comp.ItemCardList.nextItem model.itemListModel id
    in
    { prev = Maybe.map .id prev
    , next = Maybe.map .id next
    }


doSearchCmd : Flags -> UiSettings -> Int -> Model -> Cmd Msg
doSearchCmd flags settings offset model =
    case model.searchType of
        BasicSearch ->
            doSearchDefaultCmd flags settings offset model

        ContentSearch ->
            doSearchDefaultCmd flags settings offset model

        ContentOnlySearch ->
            doSearchIndexCmd flags settings offset model


doSearchDefaultCmd : Flags -> UiSettings -> Int -> Model -> Cmd Msg
doSearchDefaultCmd flags settings offset model =
    let
        smask =
            Comp.SearchMenu.getItemSearch model.searchMenuModel

        mask =
            { smask
                | limit = settings.itemSearchPageSize
                , offset = offset
            }
    in
    if offset == 0 then
        Api.itemSearch flags mask ItemSearchResp

    else
        Api.itemSearch flags mask ItemSearchAddResp


doSearchIndexCmd : Flags -> UiSettings -> Int -> Model -> Cmd Msg
doSearchIndexCmd flags settings offset model =
    case model.contentOnlySearch of
        Just q ->
            let
                mask =
                    { query = q
                    , limit = settings.itemSearchPageSize
                    , offset = offset
                    }
            in
            if offset == 0 then
                Api.itemIndexSearch flags mask ItemSearchResp

            else
                Api.itemIndexSearch flags mask ItemSearchAddResp

        Nothing ->
            -- If there is no fulltext query, render simply the most
            -- current ones
            let
                emptyMask =
                    Api.Model.ItemSearch.empty

                mask =
                    { emptyMask | limit = settings.itemSearchPageSize }
            in
            Api.itemSearch flags mask ItemSearchResp


resultsBelowLimit : UiSettings -> Model -> Bool
resultsBelowLimit settings model =
    let
        len =
            Data.Items.length model.itemListModel.results
    in
    len < settings.itemSearchPageSize
