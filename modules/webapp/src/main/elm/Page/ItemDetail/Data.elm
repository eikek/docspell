{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ItemDetail.Data exposing
    ( Model
    , Msg(..)
    , UpdateResult
    , emptyModel
    )

import Api.Model.ItemDetail exposing (ItemDetail)
import Browser.Dom as Dom
import Comp.ItemDetail
import Comp.ItemDetail.Model
import Comp.LinkTarget exposing (LinkTarget)
import Data.ItemIds exposing (ItemIds)
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
    | ItemDetailMsg Comp.ItemDetail.Model.Msg
    | ItemResp (Result Http.Error ItemDetail)
    | ScrollResult (Result Dom.Error ())
    | UiSettingsUpdated


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , linkTarget : LinkTarget
    , removedItem : Maybe String
    , selectedItems : ItemIds
    }
