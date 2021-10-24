{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Menubar exposing (view)

import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Comp.SearchMenu
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..), SearchBarMode(..))
import Styles as S
import Util.Html


view : Texts -> Model -> Html Msg
view texts model =
    let
        btnStyle =
            S.secondaryBasicButton ++ " text-sm"

        searchInput =
            Comp.SearchMenu.textSearchString
                model.searchMenuModel.textSearchModel

        powerSearchBar =
            div [ class "flex-grow flex flex-col relative" ]
                [ div
                    [ class "relative flex flex-grow flex-row" ]
                    [ Html.map PowerSearchMsg
                        (Comp.PowerSearchInput.viewInput
                            { placeholder = texts.powerSearchPlaceholder
                            , extraAttrs = []
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
                    , placeholder texts.fulltextPlaceholder
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
                        , classList [ ( "bg-gray-200 dark:bg-bluegray-600", model.searchMode == SearchBarNormal ) ]
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
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-bluegray-700 items-center text-sm"
        }
