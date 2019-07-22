module Page.Home.Data exposing (..)

import Http
import Comp.SearchMenu
import Comp.ItemList
import Comp.ItemDetail
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ItemDetail exposing (ItemDetail)

type alias Model =
    { searchMenuModel: Comp.SearchMenu.Model
    , itemListModel: Comp.ItemList.Model
    , searchInProgress: Bool
    , itemDetailModel: Comp.ItemDetail.Model
    , viewMode: ViewMode
    }

emptyModel: Model
emptyModel  =
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

type ViewMode = Listing | Detail
