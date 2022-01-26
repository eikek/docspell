{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Upload.View2 exposing (viewContent, viewSidebar)

import Comp.UploadForm
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Upload exposing (Texts)
import Page exposing (Page(..))
import Page.Upload.Data exposing (..)
import Styles


viewSidebar : Maybe String -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar _ _ _ _ _ =
    div
        [ id "sidebar"
        , class "hidden"
        ]
        []


viewContent : Texts -> Maybe String -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts sourceId flags settings model =
    let
        viewCfg =
            { sourceId = sourceId
            , showForm = True
            , lightForm = False
            }
    in
    div
        [ id "content"
        , class Styles.content
        , class "mt-4"
        ]
        [ Html.map UploadMsg
            (Comp.UploadForm.view texts.uploadForm viewCfg flags settings model.uploadForm)
        ]
