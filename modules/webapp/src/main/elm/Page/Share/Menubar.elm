{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Menubar exposing (view)

import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Data.Flags exposing (Flags)
import Data.ItemArrange
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..), SearchBarMode(..))
import Styles as S
import Util.Html


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    let
        powerSearchBar =
            div [ class "flex-grow flex flex-col relative" ]
                [ div
                    [ class "relative flex flex-grow flex-row" ]
                    [ Html.map PowerSearchMsg
                        (Comp.PowerSearchInput.viewInput
                            { placeholder = texts.powerSearchPlaceholder
                            }
                            model.powerSearchInput
                        )
                    , Html.map PowerSearchMsg
                        (Comp.PowerSearchInput.viewResult [] model.powerSearchInput)
                    ]
                , div
                    [ class "opacity-60 text-xs -mt-1.5 absolute -bottom-4"
                    ]
                    [ text "Use an "
                    , a
                        [ href "https://docspell.org/docs/query/#structure"
                        , target "_new"
                        , class S.link
                        , class "mx-1"
                        ]
                        [ i [ class "fa fa-external-link-alt mr-1" ] []
                        , text "extended search"
                        ]
                    , text " syntax."
                    ]
                ]

        contentSearchBar =
            div [ class "flex flex-grow" ]
                [ input
                    [ type_ "text"
                    , class S.textInput
                    , class "text-sm"
                    , if flags.config.fullTextSearchEnabled then
                        placeholder texts.fulltextPlaceholder

                      else
                        placeholder texts.normalSearchPlaceholder
                    , onInput SetContentSearch
                    , value (Maybe.withDefault "" model.contentSearch)
                    , Util.Html.onKeyUpCode ContentSearchKey
                    ]
                    []
                ]
    in
    MB.view
        { start =
            [ MB.CustomElement <|
                case model.searchMode of
                    SearchBarContent ->
                        contentSearchBar

                    SearchBarNormal ->
                        powerSearchBar
            , MB.CustomElement <|
                B.secondaryBasicButton
                    { label = ""
                    , icon = "fa fa-search-plus"
                    , disabled = False
                    , handler = onClick ToggleSearchBar
                    , attrs =
                        [ href "#"
                        , title texts.extendedSearch
                        , classList [ ( "bg-gray-200 dark:bg-slate-600", model.searchMode == SearchBarNormal ) ]
                        ]
                    }
            ]
        , end =
            [ MB.CustomElement <|
                B.secondaryBasicButton
                    { label = ""
                    , icon =
                        if model.searchInProgress then
                            "fa fa-sync animate-spin"

                        else
                            "fa fa-sync"
                    , disabled = model.searchInProgress
                    , handler = onClick ResetSearch
                    , attrs = [ href "#" ]
                    }
            , MB.Dropdown
                { linkIcon = "fa fa-grip-vertical"
                , label = ""
                , linkClass =
                    [ ( S.secondaryBasicButton, True )
                    ]
                , toggleMenu = ToggleViewMenu
                , menuOpen = model.viewMode.menuOpen
                , items =
                    [ { icon =
                            if model.viewMode.showGroups then
                                i [ class "fa fa-check-square font-thin" ] []

                            else
                                i [ class "fa fa-square font-thin" ] []
                      , label = texts.showItemGroups
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick ToggleShowGroups
                            ]
                      }
                    , { icon = i [ class "fa fa-list" ] []
                      , label = texts.listView
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick (ToggleArrange Data.ItemArrange.List)
                            ]
                      }
                    , { icon = i [ class "fa fa-th-large" ] []
                      , label = texts.tileView
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick (ToggleArrange Data.ItemArrange.Cards)
                            ]
                      }
                    , { label = texts.downloadAllLabel
                      , icon = i [ class "fa fa-download" ] []
                      , disabled = False
                      , attrs =
                            [ title texts.downloadAllLabel
                            , href "#"
                            , onClick ToggleDownloadAll
                            ]
                      }
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-slate-700 items-center text-sm"
        , sticky = True
        }
