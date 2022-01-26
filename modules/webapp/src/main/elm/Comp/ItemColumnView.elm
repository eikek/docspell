{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemColumnView exposing (..)

import Api.Model.ItemLight exposing (ItemLight)
import Data.ItemColumn exposing (ItemColumn(..))
import Data.ItemTemplate exposing (TemplateContext)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Attribute, Html, div, text)
import Html.Attributes exposing (class)


renderDiv :
    TemplateContext
    -> UiSettings
    -> ItemColumn
    -> List (Attribute msg)
    -> ItemLight
    -> Html msg
renderDiv ctx settings col attr item =
    case col of
        Tags ->
            div attr
                (List.map
                    (\t ->
                        div
                            [ class "label text-sm"
                            , class <| Data.UiSettings.tagColorString2 t settings
                            ]
                            [ text t.name ]
                    )
                    item.tags
                )

        _ ->
            div attr
                [ text (Data.ItemColumn.renderString ctx col item)
                ]
