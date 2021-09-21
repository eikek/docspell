{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ItemDetail.Update exposing (update)

import Api
import Browser.Navigation as Nav
import Comp.ItemDetail
import Comp.ItemDetail.Model
import Comp.LinkTarget
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Page exposing (Page(..))
import Page.ItemDetail.Data exposing (Model, Msg(..), UpdateResult)
import Scroll
import Task


update : Nav.Key -> Flags -> ItemNav -> UiSettings -> Msg -> Model -> UpdateResult
update key flags inav settings msg model =
    case msg of
        Init id ->
            let
                result =
                    Comp.ItemDetail.update key
                        flags
                        inav
                        settings
                        Comp.ItemDetail.Model.Init
                        model.detail

                task =
                    Scroll.scroll "default-layout" 0 0 0 0
            in
            { model = { model | detail = result.model }
            , cmd =
                Cmd.batch
                    [ Api.itemDetail flags id ItemResp
                    , Cmd.map ItemDetailMsg result.cmd
                    , Task.attempt ScrollResult task
                    ]
            , sub = Sub.map ItemDetailMsg result.sub
            , linkTarget = result.linkTarget
            , removedItem = result.removedItem
            }

        ItemDetailMsg lmsg ->
            let
                result =
                    Comp.ItemDetail.update key flags inav settings lmsg model.detail

                pageSwitch =
                    case result.linkTarget of
                        Comp.LinkTarget.LinkNone ->
                            Cmd.none

                        _ ->
                            Page.set key HomePage
            in
            { model = { model | detail = result.model }
            , cmd = Cmd.batch [ pageSwitch, Cmd.map ItemDetailMsg result.cmd ]
            , sub = Sub.map ItemDetailMsg result.sub
            , linkTarget = result.linkTarget
            , removedItem = result.removedItem
            }

        ItemResp (Ok item) ->
            let
                lmsg =
                    Comp.ItemDetail.Model.SetItem item
            in
            update key flags inav settings (ItemDetailMsg lmsg) model

        ItemResp (Err _) ->
            UpdateResult model Cmd.none Sub.none Comp.LinkTarget.LinkNone Nothing

        ScrollResult _ ->
            UpdateResult model Cmd.none Sub.none Comp.LinkTarget.LinkNone Nothing

        UiSettingsUpdated ->
            let
                lmsg =
                    ItemDetailMsg Comp.ItemDetail.Model.UiSettingsUpdated
            in
            update key flags inav settings lmsg model
