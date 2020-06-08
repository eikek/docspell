module Page.Home.View exposing (view)

import Comp.ItemCardList
import Comp.SearchMenu
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)


view : UiSettings -> Model -> Html Msg
view settings model =
    div [ class "home-page ui padded grid" ]
        [ div
            [ classList
                [ ( "sixteen wide mobile six wide tablet four wide computer column"
                  , True
                  )
                , ( "invisible hidden", model.menuCollapsed )
                ]
            ]
            [ div
                [ class "ui top attached ablue-comp menu"
                ]
                [ a
                    [ class "item"
                    , href "#"
                    , onClick ToggleSearchMenu
                    , title "Hide menu"
                    ]
                    [ i [ class "ui angle down icon" ] []
                    , text "Search"
                    ]
                , div [ class "right floated menu" ]
                    [ a
                        [ class "icon item"
                        , onClick ResetSearch
                        , title "Reset form"
                        , href "#"
                        ]
                        [ i [ class "undo icon" ] []
                        ]
                    , a
                        [ class "icon item"
                        , onClick DoSearch
                        , title "Run search query"
                        , href ""
                        ]
                        [ i [ class "ui search icon" ] []
                        ]
                    ]
                ]
            , div [ class "ui attached fluid segment" ]
                [ Html.map SearchMenuMsg (Comp.SearchMenu.view settings model.searchMenuModel)
                ]
            ]
        , div
            [ classList
                [ ( "sixteen wide mobile ten wide tablet twelve wide computer column"
                  , not model.menuCollapsed
                  )
                , ( "sixteen wide column", model.menuCollapsed )
                , ( "item-card-list", True )
                ]
            ]
            [ div
                [ classList
                    [ ( "invisible hidden", not model.menuCollapsed )
                    , ( "ui segment container", True )
                    ]
                ]
                [ a
                    [ class "ui basic large circular label"
                    , onClick ToggleSearchMenu
                    , href "#"
                    ]
                    [ i [ class "search icon" ] []
                    , text "Search Menu…"
                    ]
                ]
            , case model.viewMode of
                Listing ->
                    if model.searchInProgress then
                        resultPlaceholder

                    else
                        Html.map ItemCardListMsg
                            (Comp.ItemCardList.view settings model.itemListModel)

                Detail ->
                    div [] []
            ]
        , div
            [ classList
                [ ( "sixteen wide column", True )
                ]
            ]
            [ div [ class "ui basic center aligned segment" ]
                [ button
                    [ classList
                        [ ( "ui basic tiny button", True )
                        , ( "disabled", not model.moreAvailable )
                        , ( "hidden invisible", resultsBelowLimit settings model )
                        ]
                    , disabled (not model.moreAvailable || model.moreInProgress || model.searchInProgress)
                    , title "Load more items"
                    , href "#"
                    , onClick LoadMore
                    ]
                    [ if model.moreInProgress then
                        i [ class "loading spinner icon" ] []

                      else
                        i [ class "angle double down icon" ] []
                    , if model.moreAvailable then
                        text "Load more…"

                      else
                        text "That's all"
                    ]
                ]
            ]
        ]


resultPlaceholder : Html Msg
resultPlaceholder =
    div [ class "ui basic segment" ]
        [ div [ class "ui active inverted dimmer" ]
            [ div [ class "ui medium text loader" ]
                [ text "Searching …"
                ]
            ]
        , div [ class "ui middle aligned very relaxed divided basic list segment" ]
            [ div [ class "item" ]
                [ div [ class "ui fluid placeholder" ]
                    [ div [ class "full line" ] []
                    , div [ class "full line" ] []
                    ]
                ]
            , div [ class "item" ]
                [ div [ class "ui fluid placeholder" ]
                    [ div [ class "full line" ] []
                    , div [ class "full line" ] []
                    ]
                ]
            , div [ class "item" ]
                [ div [ class "ui fluid placeholder" ]
                    [ div [ class "full line" ] []
                    , div [ class "full line" ] []
                    ]
                ]
            ]
        ]
