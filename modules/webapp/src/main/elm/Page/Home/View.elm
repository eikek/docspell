module Page.Home.View exposing (view)

import Comp.ItemCardList
import Comp.SearchMenu
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)


view : Model -> Html Msg
view model =
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
                [ Html.map SearchMenuMsg (Comp.SearchMenu.view model.searchMenuModel)
                ]
            ]
        , div
            [ classList
                [ ( "sixteen wide mobile ten wide tablet twelve wide computer column"
                  , not model.menuCollapsed
                  )
                , ( "sixteen wide column", model.menuCollapsed )
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
                            (Comp.ItemCardList.view model.itemListModel)

                Detail ->
                    div [] []
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
