module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , SearchType(..)
    , SelectActionMode(..)
    , SelectViewModel
    , ViewMode(..)
    , defaultSearchType
    , doSearchCmd
    , init
    , initSelectViewModel
    , itemNav
    , menuCollapsed
    , resultsBelowLimit
    , searchTypeString
    , selectActive
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemSearch
import Browser.Dom as Dom
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.ItemDetail.EditMenu exposing (SaveNameState(..))
import Comp.ItemDetail.FormChange exposing (FormChange)
import Comp.LinkTarget exposing (LinkTarget)
import Comp.SearchMenu
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Http
import Set exposing (Set)
import Throttle exposing (Throttle)
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD


type alias Model =
    { searchMenuModel : Comp.SearchMenu.Model
    , itemListModel : Comp.ItemCardList.Model
    , searchInProgress : Bool
    , viewMode : ViewMode
    , searchOffset : Int
    , moreAvailable : Bool
    , moreInProgress : Bool
    , throttle : Throttle Msg
    , searchTypeDropdown : Comp.FixedDropdown.Model SearchType
    , searchType : SearchType
    , searchTypeForm : SearchType
    , contentOnlySearch : Maybe String
    , dragDropData : DD.DragDropData
    , scrollToCard : Maybe String
    }


type alias SelectViewModel =
    { ids : Set String
    , action : SelectActionMode
    , deleteAllConfirm : Comp.YesNoDimmer.Model
    , editModel : Comp.ItemDetail.EditMenu.Model
    , saveNameState : SaveNameState
    , saveCustomFieldState : Set String
    }


initSelectViewModel : SelectViewModel
initSelectViewModel =
    { ids = Set.empty
    , action = NoneAction
    , deleteAllConfirm = Comp.YesNoDimmer.initActive
    , editModel = Comp.ItemDetail.EditMenu.init
    , saveNameState = SaveSuccess
    , saveCustomFieldState = Set.empty
    }


type ViewMode
    = SimpleView
    | SearchView
    | SelectView SelectViewModel


init : Flags -> ViewMode -> Model
init flags viewMode =
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
    , scrollToCard = Nothing
    , viewMode = viewMode
    }


defaultSearchType : Flags -> SearchType
defaultSearchType flags =
    if flags.config.fullTextSearchEnabled then
        ContentOnlySearch

    else
        BasicSearch


menuCollapsed : Model -> Bool
menuCollapsed model =
    case model.viewMode of
        SimpleView ->
            True

        SearchView ->
            False

        SelectView _ ->
            False


selectActive : Model -> Bool
selectActive model =
    case model.viewMode of
        SimpleView ->
            False

        SearchView ->
            False

        SelectView _ ->
            True


type Msg
    = Init
    | SearchMenuMsg Comp.SearchMenu.Msg
    | ResetSearch
    | ItemCardListMsg Comp.ItemCardList.Msg
    | ItemSearchResp Bool (Result Http.Error ItemLightList)
    | ItemSearchAddResp (Result Http.Error ItemLightList)
    | DoSearch
    | ToggleSearchMenu
    | ToggleSelectView
    | LoadMore
    | UpdateThrottle
    | SetBasicSearch String
    | SearchTypeMsg (Comp.FixedDropdown.Msg SearchType)
    | KeyUpMsg (Maybe KeyCode)
    | SetContentOnly String
    | ScrollResult (Result Dom.Error ())
    | ClearItemDetailId
    | SelectAllItems
    | SelectNoItems
    | RequestDeleteSelected
    | DeleteSelectedConfirmMsg Comp.YesNoDimmer.Msg
    | EditSelectedItems
    | EditMenuMsg Comp.ItemDetail.EditMenu.Msg
    | MultiUpdateResp FormChange (Result Http.Error BasicResult)
    | ReplaceChangedItemsResp (Result Http.Error ItemLightList)
    | DeleteAllResp (Result Http.Error BasicResult)
    | UiSettingsUpdated
    | SetLinkTarget LinkTarget


type SearchType
    = BasicSearch
    | ContentSearch
    | ContentOnlySearch


type SelectActionMode
    = NoneAction
    | DeleteSelected
    | EditSelected


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


doSearchCmd : Flags -> UiSettings -> Int -> Bool -> Model -> Cmd Msg
doSearchCmd flags settings offset scroll model =
    case model.searchType of
        BasicSearch ->
            doSearchDefaultCmd flags settings offset scroll model

        ContentSearch ->
            doSearchDefaultCmd flags settings offset scroll model

        ContentOnlySearch ->
            doSearchIndexCmd flags settings offset scroll model


doSearchDefaultCmd : Flags -> UiSettings -> Int -> Bool -> Model -> Cmd Msg
doSearchDefaultCmd flags settings offset scroll model =
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
        Api.itemSearch flags mask (ItemSearchResp scroll)

    else
        Api.itemSearch flags mask ItemSearchAddResp


doSearchIndexCmd : Flags -> UiSettings -> Int -> Bool -> Model -> Cmd Msg
doSearchIndexCmd flags settings offset scroll model =
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
                Api.itemIndexSearch flags mask (ItemSearchResp scroll)

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
            Api.itemSearch flags mask (ItemSearchResp scroll)


resultsBelowLimit : UiSettings -> Model -> Bool
resultsBelowLimit settings model =
    let
        len =
            Data.Items.length model.itemListModel.results
    in
    len < settings.itemSearchPageSize
