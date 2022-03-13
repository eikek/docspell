{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Search.SideMenu exposing (view)

import Comp.Basic as B
import Comp.ItemDetail.MultiEditMenu
import Comp.MenuBar as MB
import Comp.SearchMenu
import Data.Environment as Env
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Page.SearchSideMenu exposing (Texts)
import Page.Search.Data exposing (..)
import Set
import Styles as S


view : Texts -> Env.View -> Model -> Html Msg
view texts env model =
    div
        [ class "flex flex-col"
        ]
        [ MB.viewSide
            { end =
                [ MB.CustomButton
                    { tagger = ToggleSelectView
                    , label = ""
                    , icon = Just "fa fa-tasks"
                    , title = texts.editMode
                    , inputClass =
                        [ ( S.secondaryBasicButton, True )
                        , ( "bg-gray-200 dark:bg-slate-600", selectActive model )
                        ]
                    }
                , MB.CustomButton
                    { tagger = ResetSearch
                    , label = ""
                    , icon = Just "fa fa-sync"
                    , title = texts.resetSearchForm
                    , inputClass = [ ( S.secondaryBasicButton, True ) ]
                    }
                ]
            , start = []
            , rootClasses = "text-sm w-full bg-blue-50 pt-2 hidden"
            , sticky = True
            }
        , div [ class "flex flex-col" ]
            (case model.viewMode of
                SelectView svm ->
                    case svm.action of
                        EditSelected ->
                            viewEditMenu texts env.flags svm env.settings

                        _ ->
                            viewSearch texts env model

                _ ->
                    viewSearch texts env model
            )
        ]


viewSearch : Texts -> Env.View -> Model -> List (Html Msg)
viewSearch texts env model =
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
        , sticky = True
        }
    , let
        searchMenuCfg =
            { overrideTabLook = \_ -> identity
            , selectedItems = env.selectedItems
            }
      in
      Html.map SearchMenuMsg
        (Comp.SearchMenu.viewDrop2 texts.searchMenu
            model.dragDropData
            env.flags
            searchMenuCfg
            env.settings
            model.searchMenuModel
        )
    ]


viewEditMenu : Texts -> Flags -> SelectViewModel -> UiSettings -> List (Html Msg)
viewEditMenu texts flags svm settings =
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
            [ text texts.multiEditHeader
            ]
        ]
    , div [ class S.infoMessage ]
        [ text texts.multiEditInfo
        ]
    , MB.viewSide
        { start =
            [ MB.CustomElement <|
                B.secondaryButton
                    { label = texts.close
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
        , sticky = True
        }
    , Html.map EditMenuMsg
        (Comp.ItemDetail.MultiEditMenu.view2
            texts.multiEdit
            flags
            cfg
            settings
            svm.editModel
        )
    ]
