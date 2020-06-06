module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , ViewMode(..)
    , doSearchCmd
    , init
    , itemNav
    , resultsBelowLimit
    , searchLimit
    )

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.Items
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
    { searchMenuModel = Comp.SearchMenu.emptyModel
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


searchLimit : Int
searchLimit =
    90


doSearchCmd : Flags -> Int -> Comp.SearchMenu.Model -> Cmd Msg
doSearchCmd flags offset model =
    let
        smask =
            Comp.SearchMenu.getItemSearch model

        mask =
            { smask
                | limit = searchLimit
                , offset = offset
            }
    in
    Api.itemSearch flags mask ItemSearchResp


resultsBelowLimit : Model -> Bool
resultsBelowLimit model =
    let
        len =
            Data.Items.length model.itemListModel.results
    in
    len < searchLimit
