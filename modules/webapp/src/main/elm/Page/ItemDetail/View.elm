module Page.ItemDetail.View exposing (view)

import Comp.ItemDetail
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.ItemDetail.Data exposing (Model, Msg(..))


type alias ItemNav =
    { prev : Maybe String
    , next : Maybe String
    }


view : ItemNav -> Model -> Html Msg
view inav model =
    div [ class "ui fluid container item-detail-page" ]
        [ Html.map ItemDetailMsg (Comp.ItemDetail.view inav model.detail)
        ]
