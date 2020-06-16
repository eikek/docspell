module Page.Home.View exposing (view)

import Api.Model.ItemSearch
import Comp.ItemCardList
import Comp.SearchMenu
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
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
                        , disabled model.searchInProgress
                        ]
                        [ i
                            [ classList
                                [ ( "search icon", not model.searchInProgress )
                                , ( "loading spinner icon", model.searchInProgress )
                                ]
                            ]
                            []
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
            [ viewSearchBar model
            , case model.viewMode of
                Listing ->
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


viewSearchBar : Model -> Html Msg
viewSearchBar model =
    div
        [ classList
            [ ( "invisible hidden", not model.menuCollapsed )
            , ( "ui menu container", True )
            ]
        ]
        [ a
            [ class "item"
            , onClick ToggleSearchMenu
            , href "#"
            , title "Open search menu"
            ]
            [ i [ class "angle left icon" ] []
            , i [ class "icons" ]
                [ i [ class "grey bars icon" ] []
                , i [ class "bottom left corner search icon" ] []
                , if hasMoreSearch model then
                    i [ class "top right blue corner circle icon" ] []

                  else
                    span [ class "hidden invisible" ] []
                ]
            ]
        , div [ class "ui category search item" ]
            [ div [ class "ui transparent icon input" ]
                [ input
                    [ type_ "text"
                    , placeholder "Basic search…"
                    , onInput SetBasicSearch
                    , Maybe.map value model.searchMenuModel.allNameModel
                        |> Maybe.withDefault (value "")
                    ]
                    []
                , i
                    [ classList
                        [ ( "search link icon", not model.searchInProgress )
                        , ( "loading spinner icon", model.searchInProgress )
                        ]
                    ]
                    []
                ]
            ]
        , div [ class "ui category search item" ]
            [ div [ class "ui transparent icon input" ]
                [ input
                    [ type_ "text"
                    , placeholder "Fulltext search…"
                    , onInput SetFulltextSearch
                    , Maybe.map value model.searchMenuModel.fulltextModel
                        |> Maybe.withDefault (value "")
                    ]
                    []
                , i
                    [ classList
                        [ ( "search link icon", not model.searchInProgress )
                        , ( "loading spinner icon", model.searchInProgress )
                        ]
                    ]
                    []
                ]
            ]
        ]


hasMoreSearch : Model -> Bool
hasMoreSearch model =
    let
        is =
            Comp.SearchMenu.getItemSearch model.searchMenuModel

        is_ =
            { is | allNames = Nothing, fullText = Nothing }
    in
    is_ /= Api.Model.ItemSearch.empty
