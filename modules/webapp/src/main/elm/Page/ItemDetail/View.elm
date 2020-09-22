module Page.ItemDetail.View exposing (view)

import Comp.ItemDetail
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.ItemDetail.Data exposing (Model, Msg(..))


view : ItemNav -> UiSettings -> Model -> Html Msg
view inav settings model =
    div [ class "ui fluid container item-detail-page" ]
        [ Html.map ItemDetailMsg (Comp.ItemDetail.view inav settings model.detail)
        ]
