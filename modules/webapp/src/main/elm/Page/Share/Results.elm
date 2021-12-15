{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Results exposing (view)

import Api
import Comp.ItemCardList
import Data.Flags exposing (Flags)
import Data.ItemSelection
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Share exposing (Texts)
import Page exposing (Page(..))
import Page.Share.Data exposing (Model, Msg(..))
import Set


view : Texts -> UiSettings -> Flags -> String -> Model -> Html Msg
view texts settings flags shareId model =
    let
        viewCfg =
            { current = Nothing
            , selection = Data.ItemSelection.Inactive
            , previewUrl = \attach -> Api.shareAttachmentPreviewURL attach.id
            , previewUrlFallback = \item -> Api.shareItemBasePreviewURL item.id
            , attachUrl = .id >> Api.shareFileURL
            , detailPage = \item -> ShareDetailPage shareId item.id
            , arrange = model.viewMode.arrange
            , showGroups = model.viewMode.showGroups
            , rowOpen = \id -> Set.member id model.viewMode.rowsOpen
            }
    in
    div []
        [ Html.map ItemListMsg
            (Comp.ItemCardList.view texts.itemCardList viewCfg settings flags model.itemListModel)
        ]
