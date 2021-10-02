{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.View exposing (viewContent, viewSidebar)

import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (..)
import Styles as S


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar _ visible _ _ _ =
    div
        [ id "sidebar"
        , classList [ ( "hidden", not visible ) ]
        ]
        [ text "sidebar" ]


viewContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts flags _ model =
    div
        [ id "content"
        , class "h-full flex flex-col"
        , class S.content
        ]
        [ h1 [ class S.header1 ]
            [ text "Share Page!"
            ]
        ]
