{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.LoadMore exposing (view)

import Comp.Basic as B
import Comp.ItemCardList
import Html exposing (Html, div)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..))


view : Texts -> Model -> Html Msg
view texts model =
    let
        noMore =
            requestedResultSize model > currentResultSize model
    in
    div [ class "py-8 flex flex-row items-center justify-center" ]
        [ B.secondaryBasicButton
            { label =
                if noMore then
                    texts.thatsAll

                else
                    texts.loadMore
            , icon =
                if model.searchInProgress then
                    "fa fa-circle-notch animate-spin"

                else
                    "fa fa-angle-double-down"
            , disabled = noMore
            , handler = onClick LoadNextPage
            , attrs =
                [ href "#"
                ]
            }
        ]


requestedResultSize : Model -> Int
requestedResultSize model =
    model.viewMode.offset + model.viewMode.pageSize


currentResultSize : Model -> Int
currentResultSize model =
    Comp.ItemCardList.size model.itemListModel
