{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Results exposing (view)

import Api
import Comp.ItemCardList
import Data.ItemSelection
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..))


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        viewCfg =
            { current = Nothing
            , selection = Data.ItemSelection.Inactive
            , previewUrl = \attach -> Api.shareAttachmentPreviewURL attach.id
            , previewUrlFallback = \item -> Api.shareItemBasePreviewURL item.id
            }
    in
    div []
        [ Html.map ItemListMsg
            (Comp.ItemCardList.view2 texts.itemCardList viewCfg settings model.itemListModel)
        ]
