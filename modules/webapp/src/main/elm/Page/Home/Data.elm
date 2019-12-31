module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , ViewMode(..)
    , emptyModel
    , itemNav
    )

import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemList
import Comp.SearchMenu
import Http


type alias Model =
    { searchMenuModel : Comp.SearchMenu.Model
    , itemListModel : Comp.ItemList.Model
    , searchInProgress : Bool
    , viewMode : ViewMode
    }


emptyModel : Model
emptyModel =
    { searchMenuModel = Comp.SearchMenu.emptyModel
    , itemListModel = Comp.ItemList.emptyModel
    , searchInProgress = False
    , viewMode = Listing
    }


type Msg
    = Init
    | SearchMenuMsg Comp.SearchMenu.Msg
    | ResetSearch
    | ItemListMsg Comp.ItemList.Msg
    | ItemSearchResp (Result Http.Error ItemLightList)
    | DoSearch


type ViewMode
    = Listing
    | Detail


itemNav : String -> Model -> { prev : Maybe String, next : Maybe String }
itemNav id model =
    let
        prev =
            Comp.ItemList.prevItem model.itemListModel id

        next =
            Comp.ItemList.nextItem model.itemListModel id
    in
    { prev = Maybe.map .id prev
    , next = Maybe.map .id next
    }
