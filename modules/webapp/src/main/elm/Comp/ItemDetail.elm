{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.ItemDetail exposing
    ( Model
    , emptyModel
    , update
    , view2
    )

import Browser.Navigation as Nav
import Comp.ItemDetail.Model exposing (Msg(..), UpdateResult)
import Comp.ItemDetail.Update
import Comp.ItemDetail.View2
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Messages.Comp.ItemDetail exposing (Texts)
import Page exposing (Page(..))


type alias Model =
    Comp.ItemDetail.Model.Model


emptyModel : Model
emptyModel =
    Comp.ItemDetail.Model.emptyModel


update : Nav.Key -> Flags -> ItemNav -> UiSettings -> Msg -> Model -> UpdateResult
update =
    Comp.ItemDetail.Update.update


view2 : Texts -> ItemNav -> UiSettings -> Model -> Html Msg
view2 =
    Comp.ItemDetail.View2.view
