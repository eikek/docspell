module Page.ItemDetail.View2 exposing (viewContent, viewSidebar)

import Comp.Basic as B
import Comp.ItemDetail
import Comp.ItemDetail.EditForm
import Comp.ItemDetail.Model
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.ItemDetail.Data exposing (..)
import Styles as S


viewSidebar : Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar visible _ settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ div
            [ class S.header2
            , class "font-bold mt-2"
            ]
            [ i [ class "fa fa-pencil-alt mr-2" ] []
            , text "Edit Metadata"
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
                            [ title "Collapse/Expand"
                            , href "#"
                            ]
                        }
                ]
            , end = []
            , rootClasses = "text-sm mb-3 "
            }
        , Html.map ItemDetailMsg
            (Comp.ItemDetail.EditForm.view2 settings model.detail)
        ]


viewContent : ItemNav -> Flags -> UiSettings -> Model -> Html Msg
viewContent inav _ settings model =
    div
        [ id "content"
        , class S.content
        ]
        [ Html.map ItemDetailMsg
            (Comp.ItemDetail.view2 inav settings model.detail)
        ]
