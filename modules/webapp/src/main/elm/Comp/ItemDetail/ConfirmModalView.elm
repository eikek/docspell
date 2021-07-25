{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.ItemDetail.ConfirmModalView exposing (view)

import Comp.ConfirmModal
import Comp.ItemDetail.Model exposing (..)
import Html exposing (..)
import Messages.Comp.ItemDetail.ConfirmModal exposing (Texts)


view : Texts -> ConfirmModalValue -> Model -> Html Msg
view texts modal itemModel =
    case modal of
        ConfirmModalReprocessItem msg ->
            Comp.ConfirmModal.view
                (makeSettings texts
                    msg
                    ItemModalCancelled
                    (texts.confirmReprocessItem itemModel.item.state)
                )

        ConfirmModalReprocessFile msg ->
            Comp.ConfirmModal.view
                (makeSettings texts
                    msg
                    AttachModalCancelled
                    (texts.confirmReprocessFile itemModel.item.state)
                )

        ConfirmModalDeleteItem msg ->
            Comp.ConfirmModal.view
                (makeSettings texts
                    msg
                    ItemModalCancelled
                    texts.confirmDeleteItem
                )

        ConfirmModalDeleteFile msg ->
            Comp.ConfirmModal.view
                (makeSettings texts
                    msg
                    AttachModalCancelled
                    texts.confirmDeleteFile
                )

        ConfirmModalDeleteAllFiles msg ->
            Comp.ConfirmModal.view
                (makeSettings texts
                    msg
                    AttachModalCancelled
                    texts.confirmDeleteAllFiles
                )


makeSettings : Texts -> Msg -> Msg -> String -> Comp.ConfirmModal.Settings Msg
makeSettings texts confirm cancel confirmMsg =
    Comp.ConfirmModal.defaultSettings
        confirm
        cancel
        texts.basics.ok
        texts.basics.cancel
        confirmMsg
