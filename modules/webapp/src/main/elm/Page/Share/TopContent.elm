{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.TopContent exposing (view)

import Comp.DownloadAll
import Data.Flags exposing (Flags)
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..), TopContentModel(..))


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    case model.topContent of
        TopContentHidden ->
            span [ class "hidden" ] []

        TopContentDownload dm ->
            div [ class "mb-4 border-l border-r border-b dark:border-slate-600" ]
                [ Html.map DownloadAllMsg
                    (Comp.DownloadAll.view flags texts.downloadAll dm)
                ]
