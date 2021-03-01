module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , SearchParam
    , SearchType(..)
    , SelectActionMode(..)
    , SelectViewModel
    , ViewMode(..)
    , doSearchCmd
    , editActive
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
import Api.Model.SearchStats exposing (SearchStats)
import Browser.Dom as Dom
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.ItemDetail.FormChange exposing (FormChange)
import Comp.ItemDetail.MultiEditMenu exposing (SaveNameState(..))
import Comp.LinkTarget exposing (LinkTarget)
import Comp.SearchMenu
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.ItemQuery as Q
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
    , searchTypeDropdownValue : SearchType
    , lastSearchType : SearchType
    , dragDropData : DD.DragDropData
    , scrollToCard : Maybe String
    , searchStats : SearchStats
    , powerSearchInput : Maybe String
    }


type alias SelectViewModel =
    { ids : Set String
    , action : SelectActionMode
    , deleteAllConfirm : Comp.YesNoDimmer.Model
    , editModel : Comp.ItemDetail.MultiEditMenu.Model
    , saveNameState : SaveNameState
    , saveCustomFieldState : Set String
    }


initSelectViewModel : SelectViewModel
initSelectViewModel =
    { ids = Set.empty
    , action = NoneAction
    , deleteAllConfirm = Comp.YesNoDimmer.initActive
    , editModel = Comp.ItemDetail.MultiEditMenu.init
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
        searchMenuModel =
            Comp.SearchMenu.init flags

        searchTypeOptions =
            if flags.config.fullTextSearchEnabled then
                [ BasicSearch, ContentOnlySearch ]

            else
                [ BasicSearch ]
    in
    { searchMenuModel = searchMenuModel
    , itemListModel = Comp.ItemCardList.init
    , searchInProgress = False
    , searchOffset = 0
    , moreAvailable = True
    , moreInProgress = False
    , throttle = Throttle.create 1
    , searchTypeDropdown =
        Comp.FixedDropdown.initMap searchTypeString
            searchTypeOptions
    , searchTypeDropdownValue =
        if Comp.SearchMenu.isFulltextSearch searchMenuModel then
            ContentOnlySearch

        else
            BasicSearch
    , lastSearchType = BasicSearch
    , dragDropData =
        DD.DragDropData DD.init Nothing
    , scrollToCard = Nothing
    , viewMode = viewMode
    , searchStats = Api.Model.SearchStats.empty
    , powerSearchInput = Nothing
    }


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


editActive : Model -> Bool
editActive model =
    case model.viewMode of
        SimpleView ->
            False

        SearchView ->
            False

        SelectView svm ->
            svm.action == EditSelected


type Msg
    = Init
    | SearchMenuMsg Comp.SearchMenu.Msg
    | ResetSearch
    | ItemCardListMsg Comp.ItemCardList.Msg
    | ItemSearchResp Bool (Result Http.Error ItemLightList)
    | ItemSearchAddResp (Result Http.Error ItemLightList)
    | DoSearch SearchType
    | ToggleSearchMenu
    | ToggleSelectView
    | LoadMore
    | UpdateThrottle
    | SetBasicSearch String
    | SearchTypeMsg (Comp.FixedDropdown.Msg SearchType)
    | ToggleSearchType
    | KeyUpSearchbarMsg (Maybe KeyCode)
    | ScrollResult (Result Dom.Error ())
    | ClearItemDetailId
    | SelectAllItems
    | SelectNoItems
    | RequestDeleteSelected
    | DeleteSelectedConfirmMsg Comp.YesNoDimmer.Msg
    | EditSelectedItems
    | EditMenuMsg Comp.ItemDetail.MultiEditMenu.Msg
    | MultiUpdateResp FormChange (Result Http.Error BasicResult)
    | ReplaceChangedItemsResp (Result Http.Error ItemLightList)
    | DeleteAllResp (Result Http.Error BasicResult)
    | UiSettingsUpdated
    | SetLinkTarget LinkTarget
    | SearchStatsResp (Result Http.Error SearchStats)
    | TogglePreviewFullWidth
    | SetPowerSearch String
    | KeyUpPowerSearchbarMsg (Maybe KeyCode)


type SearchType
    = BasicSearch
    | ContentOnlySearch


type SelectActionMode
    = NoneAction
    | DeleteSelected
    | EditSelected


type alias SearchParam =
    { flags : Flags
    , searchType : SearchType
    , pageSize : Int
    , offset : Int
    , scroll : Bool
    }


searchTypeString : SearchType -> String
searchTypeString st =
    case st of
        BasicSearch ->
            "Names"

        ContentOnlySearch ->
            "Contents"


itemNav : String -> Model -> ItemNav
itemNav id model =
    Data.ItemNav.fromList model.itemListModel.results id


doSearchCmd : SearchParam -> Model -> Cmd Msg
doSearchCmd param model =
    doSearchDefaultCmd param model


doSearchDefaultCmd : SearchParam -> Model -> Cmd Msg
doSearchDefaultCmd param model =
    let
        smask =
            Q.request <|
                Q.and
                    [ Comp.SearchMenu.getItemQuery model.searchMenuModel
                    , Maybe.map Q.Fragment model.powerSearchInput
                    ]

        mask =
            { smask
                | limit = Just param.pageSize
                , offset = Just param.offset
            }
    in
    if param.offset == 0 then
        Cmd.batch
            [ Api.itemSearch param.flags mask (ItemSearchResp param.scroll)
            , Api.itemSearchStats param.flags mask SearchStatsResp
            ]

    else
        Api.itemSearch param.flags mask ItemSearchAddResp


resultsBelowLimit : UiSettings -> Model -> Bool
resultsBelowLimit settings model =
    let
        len =
            Data.Items.length model.itemListModel.results
    in
    len < settings.itemSearchPageSize
