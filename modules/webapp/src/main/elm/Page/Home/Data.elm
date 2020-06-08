module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , ViewMode(..)
    , doSearchCmd
    , init
    , itemNav
    , resultsBelowLimit
    )

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Http


type alias Model =
    { searchMenuModel : Comp.SearchMenu.Model
    , itemListModel : Comp.ItemCardList.Model
    , searchInProgress : Bool
    , viewMode : ViewMode
    , menuCollapsed : Bool
    , searchOffset : Int
    , moreAvailable : Bool
    , moreInProgress : Bool
    }


init : Flags -> Model
init _ =
    { searchMenuModel = Comp.SearchMenu.init
    , itemListModel = Comp.ItemCardList.init
    , searchInProgress = False
    , viewMode = Listing
    , menuCollapsed = False
    , searchOffset = 0
    , moreAvailable = True
    , moreInProgress = False
    }


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


type ViewMode
    = Listing
    | Detail


itemNav : String -> Model -> { prev : Maybe String, next : Maybe String }
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


resultsBelowLimit : UiSettings -> Model -> Bool
resultsBelowLimit settings model =
    let
        len =
            Data.Items.length model.itemListModel.results
    in
    len < settings.itemSearchPageSize
