{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ItemDetail.View2 exposing (viewContent, viewSidebar)

import Comp.Basic as B
import Comp.ItemDetail
import Comp.ItemDetail.EditForm
import Comp.ItemDetail.Model
import Comp.MenuBar as MB
import Data.Environment as Env
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Page.ItemDetail exposing (Texts)
import Page.ItemDetail.Data exposing (..)
import Styles as S


viewSidebar : Texts -> Env.View -> Model -> Html Msg
viewSidebar texts env model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not env.sidebarVisible ) ]
        ]
        [ div
            [ class S.header2
            , class "font-bold mt-2"
            ]
            [ i [ class "fa fa-pencil-alt mr-2" ] []
            , text texts.editMetadata
            ]
        , MB.viewSide
            { start =
                [ MB.CustomElement <|
                    B.secondaryBasicButton
                        { label = ""
                        , icon = "fa fa-expand-alt"
                        , disabled = model.detail.item.state == "created"
                        , handler = onClick (ItemDetailMsg Comp.ItemDetail.Model.ToggleOpenAllAkkordionTabs)
                        , attrs =
                            [ title texts.collapseExpand
                            , href "#"
                            ]
                        }
                ]
            , end = []
            , rootClasses = "text-sm mb-3 "
            , sticky = True
            }
        , Html.map ItemDetailMsg
            (Comp.ItemDetail.EditForm.view2 texts.editForm env.flags env.settings model.detail)
        ]


viewContent : Texts -> ItemNav -> Env.View -> Model -> Html Msg
viewContent texts inav env model =
    div
        [ id "content"
        , class S.content
        ]
        [ Html.map ItemDetailMsg
            (Comp.ItemDetail.view2 texts.itemDetail inav env model.detail)
        ]
