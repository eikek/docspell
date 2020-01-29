module Page.Home.View exposing (view)

import Comp.ItemList
import Comp.SearchMenu
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)


view : Model -> Html Msg
view model =
    div [ class "home-page ui padded grid" ]
        [ div [ class "four wide column" ]
            [ div [ class "ui top attached ablue-comp menu" ]
                [ h4 [ class "header item" ]
                    [ text "Search"
                    ]
                , div [ class "right floated menu" ]
                    [ a
                        [ class "item"
                        , onClick ResetSearch
                        , href "#"
                        ]
                        [ i [ class "undo icon" ] []
                        ]
                    , a
                        [ class "item"
                        , onClick DoSearch
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
        , div [ class "twelve wide column" ]
            [ case model.viewMode of
                Listing ->
                    if model.searchInProgress then
                        resultPlaceholder

                    else
                        Html.map ItemListMsg (Comp.ItemList.view model.itemListModel)

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
