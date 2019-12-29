module Page.Home.Data exposing
    ( Model
    , Msg(..)
    , ViewMode(..)
    , emptyModel
    )

import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemLightList exposing (ItemLightList)
import Comp.ItemDetail
import Comp.ItemList
import Comp.SearchMenu
import Http


type alias Model =
    { searchMenuModel : Comp.SearchMenu.Model
    , itemListModel : Comp.ItemList.Model
    , searchInProgress : Bool
    , itemDetailModel : Comp.ItemDetail.Model
    , viewMode : ViewMode
    }


emptyModel : Model
emptyModel =
    { searchMenuModel = Comp.SearchMenu.emptyModel
    , itemListModel = Comp.ItemList.emptyModel
    , itemDetailModel = Comp.ItemDetail.emptyModel
    , searchInProgress = False
    , viewMode = Listing
    }


type Msg
    = Init
    | SearchMenuMsg Comp.SearchMenu.Msg
    | ItemListMsg Comp.ItemList.Msg
    | ItemSearchResp (Result Http.Error ItemLightList)
    | DoSearch
    | ItemDetailMsg Comp.ItemDetail.Msg
    | ItemDetailResp (Result Http.Error ItemDetail)


type ViewMode
    = Listing
    | Detail
