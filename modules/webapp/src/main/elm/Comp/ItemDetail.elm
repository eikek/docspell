module Comp.ItemDetail exposing
    ( Model
    , emptyModel
    , update
    , view
    )

import Browser.Navigation as Nav
import Comp.ItemDetail.Model exposing (Msg(..))
import Comp.ItemDetail.Update
import Comp.ItemDetail.View exposing (..)
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


update : Nav.Key -> Flags -> ItemNav -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update =
    Comp.ItemDetail.Update.update


view : ItemNav -> UiSettings -> Model -> Html Msg
view =
    Comp.ItemDetail.View.view
