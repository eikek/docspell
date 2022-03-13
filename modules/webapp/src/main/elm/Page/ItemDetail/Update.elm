{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ItemDetail.Update exposing (update)

import Api
import Comp.ItemDetail
import Comp.ItemDetail.Model
import Comp.LinkTarget
import Data.Environment as Env
import Data.ItemIds
import Data.ItemNav exposing (ItemNav)
import Page exposing (Page(..))
import Page.ItemDetail.Data exposing (Model, Msg(..), UpdateResult)
import Scroll
import Task


update : ItemNav -> Env.Update -> Msg -> Model -> UpdateResult
update inav env msg model =
    case msg of
        Init id ->
            let
                result =
                    Comp.ItemDetail.update inav
                        env
                        Comp.ItemDetail.Model.Init
                        model.detail

                task =
                    Scroll.scroll "default-layout" 0 0 0 0
            in
            { model = { model | detail = result.model }
            , cmd =
                Cmd.batch
                    [ Api.itemDetail env.flags id ItemResp
                    , Cmd.map ItemDetailMsg result.cmd
                    , Task.attempt ScrollResult task
                    ]
            , sub = Sub.map ItemDetailMsg result.sub
            , linkTarget = result.linkTarget
            , removedItem = result.removedItem
            , selectedItems = env.selectedItems
            }

        ItemDetailMsg lmsg ->
            let
                result =
                    Comp.ItemDetail.update inav env lmsg model.detail

                pageSwitch =
                    case result.linkTarget of
                        Comp.LinkTarget.LinkNone ->
                            Cmd.none

                        _ ->
                            Page.set env.key (SearchPage Nothing)
            in
            { model = { model | detail = result.model }
            , cmd = Cmd.batch [ pageSwitch, Cmd.map ItemDetailMsg result.cmd ]
            , sub = Sub.map ItemDetailMsg result.sub
            , linkTarget = result.linkTarget
            , removedItem = result.removedItem
            , selectedItems = Data.ItemIds.apply env.selectedItems result.selectionChange
            }

        ItemResp (Ok item) ->
            let
                lmsg =
                    Comp.ItemDetail.Model.SetItem item
            in
            update inav env (ItemDetailMsg lmsg) model

        ItemResp (Err _) ->
            unit env model

        ScrollResult _ ->
            unit env model

        UiSettingsUpdated ->
            let
                lmsg =
                    ItemDetailMsg Comp.ItemDetail.Model.UiSettingsUpdated
            in
            update inav env lmsg model


unit : Env.Update -> Model -> UpdateResult
unit env model =
    { model = model
    , cmd = Cmd.none
    , sub = Sub.none
    , linkTarget = Comp.LinkTarget.LinkNone
    , removedItem = Nothing
    , selectedItems = env.selectedItems
    }
