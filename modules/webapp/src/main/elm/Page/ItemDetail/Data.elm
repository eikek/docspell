module Page.ItemDetail.Data exposing (Model, Msg(..), emptyModel)

import Api.Model.ItemDetail exposing (ItemDetail)
import Comp.ItemDetail
import Comp.ItemDetail.Update
import Http


type alias Model =
    { detail : Comp.ItemDetail.Model
    }


emptyModel : Model
emptyModel =
    { detail = Comp.ItemDetail.emptyModel
    }


type Msg
    = Init String
    | ItemDetailMsg Comp.ItemDetail.Update.Msg
    | ItemResp (Result Http.Error ItemDetail)
