module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , ViewMode(..)
    , emptyModel
    , itemNav
    )

import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemCardList
import Comp.SearchMenu
import Http


type alias Model =
    { searchMenuModel : Comp.SearchMenu.Model
    , itemListModel : Comp.ItemCardList.Model
    , searchInProgress : Bool
    , viewMode : ViewMode
    }


emptyModel : Model
emptyModel =
    { searchMenuModel = Comp.SearchMenu.emptyModel
    , itemListModel = Comp.ItemCardList.init
    , searchInProgress = False
    , viewMode = Listing
    }


type Msg
    = Init
    | SearchMenuMsg Comp.SearchMenu.Msg
    | ResetSearch
    | ItemCardListMsg Comp.ItemCardList.Msg
    | ItemSearchResp (Result Http.Error ItemLightList)
    | DoSearch


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
