module Comp.ItemDetail exposing
    ( Model
    , emptyModel
    , update
    , view
    , view2
    )

import Browser.Navigation as Nav
import Comp.ItemDetail.Model exposing (Msg(..), UpdateResult)
import Comp.ItemDetail.Update
import Comp.ItemDetail.View
import Comp.ItemDetail.View2
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Page exposing (Page(..))


type alias Model =
    Comp.ItemDetail.Model.Model


emptyModel : Model
emptyModel =
    Comp.ItemDetail.Model.emptyModel


update : Nav.Key -> Flags -> ItemNav -> UiSettings -> Msg -> Model -> UpdateResult
update =
    Comp.ItemDetail.Update.update


view : ItemNav -> UiSettings -> Model -> Html Msg
view =
    Comp.ItemDetail.View.view


view2 : ItemNav -> UiSettings -> Model -> Html Msg
view2 =
    Comp.ItemDetail.View2.view
