module Page.Home.SideMenu exposing (view)

import Comp.Basic as B
import Comp.ItemDetail.MultiEditMenu
import Comp.MenuBar as MB
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.Home.Data exposing (..)
import Set
import Styles as S


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    div
        [ class "flex flex-col"
        ]
        [ MB.viewSide
            { end =
                [ MB.CustomButton
                    { tagger = ToggleSelectView
                    , label = ""
                    , icon = Just "fa fa-tasks"
                    , title = "Edit Mode"
                    , inputClass =
                        [ ( S.secondaryBasicButton, True )
                        , ( "bg-gray-200 dark:bg-bluegray-600", selectActive model )
                        ]
                    }
                , MB.CustomButton
                    { tagger = ResetSearch
                    , label = ""
                    , icon = Just "fa fa-sync"
                    , title = "Reset search form"
                    , inputClass = [ ( S.secondaryBasicButton, True ) ]
                    }
                ]
            , start = []
            , rootClasses = "text-sm w-full bg-blue-50 pt-2 hidden"
            }
        , div [ class "flex flex-col" ]
            (case model.viewMode of
                SelectView svm ->
                    case svm.action of
                        EditSelected ->
                            viewEditMenu svm settings

                        _ ->
                            viewSearch flags settings model

                _ ->
                    viewSearch flags settings model
            )
        ]


viewSearch : Flags -> UiSettings -> Model -> List (Html Msg)
viewSearch flags settings model =
    [ MB.viewSide
        { start =
            [ MB.CustomElement <|
                B.secondaryBasicButton
                    { label = ""
                    , icon = "fa fa-expand-alt"
                    , handler = onClick (SearchMenuMsg Comp.SearchMenu.ToggleOpenAllAkkordionTabs)
                    , attrs = [ href "#" ]
                    , disabled = False
                    }
            ]
        , end = []
        , rootClasses = "my-1 text-xs hidden sm:flex"
        }
    , Html.map SearchMenuMsg
        (Comp.SearchMenu.viewDrop2 model.dragDropData
            flags
            settings
            model.searchMenuModel
        )
    ]


viewEditMenu : SelectViewModel -> UiSettings -> List (Html Msg)
viewEditMenu svm settings =
    let
        cfg_ =
            Comp.ItemDetail.MultiEditMenu.defaultViewConfig

        cfg =
            { cfg_
                | nameState = svm.saveNameState
                , customFieldState =
                    \fId ->
                        if Set.member fId svm.saveCustomFieldState then
                            Comp.ItemDetail.MultiEditMenu.Saving

                        else
                            Comp.ItemDetail.MultiEditMenu.SaveSuccess
            }
    in
    [ div [ class S.header2 ]
        [ i [ class "fa fa-edit" ] []
        , span [ class "ml-2" ]
            [ text "Multi-Edit"
            ]
        ]
    , div [ class S.infoMessage ]
        [ text "Note that a change here immediatly affects all selected items on the right!"
        ]
    , MB.viewSide
        { start =
            [ MB.CustomElement <|
                B.secondaryButton
                    { label = "Close"
                    , disabled = False
                    , icon = "fa fa-times"
                    , handler = onClick ToggleSelectView
                    , attrs =
                        [ href "#"
                        ]
                    }
            ]
        , end = []
        , rootClasses = "mt-2 text-sm"
        }
    , Html.map EditMenuMsg
        (Comp.ItemDetail.MultiEditMenu.view2 cfg settings svm.editModel)
    ]
