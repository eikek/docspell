module Page.Home.View exposing (view)

import Api.Model.ItemSearch
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Util.Html


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
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
                [ class "ui top attached ablue-comp icon menu"
                ]
                [ a
                    [ class "borderless item"
                    , href "#"
                    , onClick ToggleSearchMenu
                    , title "Hide menu"
                    ]
                    [ i [ class "ui angle down icon" ] []
                    ]
                , div [ class "right floated menu" ]
                    [ a
                        [ class "borderless item"
                        , onClick ResetSearch
                        , title "Reset form"
                        , href "#"
                        ]
                        [ i [ class "undo icon" ] []
                        ]
                    , a
                        [ class "borderless item"
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
                [ Html.map SearchMenuMsg (Comp.SearchMenu.view flags settings model.searchMenuModel)
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
            [ viewSearchBar flags model
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


viewSearchBar : Flags -> Model -> Html Msg
viewSearchBar flags model =
    let
        searchTypeItem =
            Comp.FixedDropdown.Item
                model.searchTypeForm
                (searchTypeString model.searchTypeForm)

        searchInput =
            case model.searchTypeForm of
                BasicSearch ->
                    model.searchMenuModel.allNameModel

                ContentSearch ->
                    model.searchMenuModel.fulltextModel

                ContentOnlySearch ->
                    model.contentOnlySearch

        searchTypeClass =
            if flags.config.fullTextSearchEnabled then
                "compact"

            else
                "hidden invisible"
    in
    div
        [ classList
            [ ( "invisible hidden", not model.menuCollapsed )
            , ( "ui secondary stackable menu container", True )
            ]
        ]
        [ a
            [ class "item"
            , onClick ToggleSearchMenu
            , href "#"
            , if model.searchTypeForm == ContentOnlySearch then
                title "Search menu disabled"

              else
                title "Open search menu"
            ]
            [ i [ class "angle left icon" ] []
            , i [ class "icons" ]
                [ i [ class "grey bars icon" ] []
                , i [ class "bottom left corner search icon" ] []
                , if model.searchTypeForm == ContentOnlySearch then
                    i [ class "top right red corner delete icon" ] []

                  else if hasMoreSearch model then
                    i [ class "top right blue corner circle icon" ] []

                  else
                    span [ class "hidden invisible" ] []
                ]
            ]
        , div [ class "item" ]
            [ div [ class "ui left icon right action input" ]
                [ i
                    [ classList
                        [ ( "search link icon", not model.searchInProgress )
                        , ( "loading spinner icon", model.searchInProgress )
                        ]
                    , href "#"
                    , onClick DoSearch
                    ]
                    []
                , input
                    [ type_ "text"
                    , placeholder "Quick Search …"
                    , onInput SetBasicSearch
                    , Util.Html.onKeyUpCode KeyUpMsg
                    , Maybe.map value searchInput
                        |> Maybe.withDefault (value "")
                    ]
                    []
                , Html.map SearchTypeMsg
                    (Comp.FixedDropdown.viewStyled searchTypeClass
                        (Just searchTypeItem)
                        model.searchTypeDropdown
                    )
                ]
            ]
        ]


hasMoreSearch : Model -> Bool
hasMoreSearch model =
    let
        is =
            Comp.SearchMenu.getItemSearch model.searchMenuModel

        is_ =
            case model.searchType of
                BasicSearch ->
                    { is | allNames = Nothing }

                ContentSearch ->
                    { is | fullText = Nothing }

                ContentOnlySearch ->
                    Api.Model.ItemSearch.empty
    in
    is_ /= Api.Model.ItemSearch.empty
