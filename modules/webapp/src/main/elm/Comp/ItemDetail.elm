{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemDetail exposing
    ( Model
    , emptyModel
    , update
    , view2
    )

import Comp.ItemDetail.Model exposing (Msg(..), UpdateResult)
import Comp.ItemDetail.Update
import Comp.ItemDetail.View2
import Data.Environment as Env
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


update : ItemNav -> Env.Update -> Msg -> Model -> UpdateResult
update =
    Comp.ItemDetail.Update.update


view2 : Texts -> ItemNav -> Env.View -> Model -> Html Msg
view2 =
    Comp.ItemDetail.View2.view
