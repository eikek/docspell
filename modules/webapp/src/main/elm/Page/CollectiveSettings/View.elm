module Page.CollectiveSettings.View exposing (view)

import Api.Model.TagCount exposing (TagCount)
import Comp.CollectiveSettingsForm
import Comp.SourceManage
import Comp.UserManage
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.CollectiveSettings.Data exposing (..)
import Util.Html exposing (classActive)
import Util.Maybe
import Util.Size


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    div [ class "collectivesetting-page ui padded grid" ]
        [ div [ class "sixteen wide mobile four wide tablet four wide computer column" ]
            [ h4 [ class "ui top attached ablue-comp header" ]
                [ text "Collective"
                ]
            , div [ class "ui attached fluid segment" ]
                [ div [ class "ui fluid vertical secondary menu" ]
                    [ div
                        [ classActive (model.currentTab == Just InsightsTab) "link icon item"
                        , onClick (SetTab InsightsTab)
                        ]
                        [ i [ class "chart bar outline icon" ] []
                        , text "Insights"
                        ]
                    , div
                        [ classActive (model.currentTab == Just SourceTab) "link icon item"
                        , onClick (SetTab SourceTab)
                        ]
                        [ Icons.sourceIcon ""
                        , text "Sources"
                        ]
                    , div
                        [ classActive (model.currentTab == Just SettingsTab) "link icon item"
                        , onClick (SetTab SettingsTab)
                        ]
                        [ i [ class "cog icon" ] []
                        , text "Settings"
                        ]
                    , div
                        [ classActive (model.currentTab == Just UserTab) "link icon item"
                        , onClick (SetTab UserTab)
                        ]
                        [ i [ class "user icon" ] []
                        , text "Users"
                        ]
                    ]
                ]
            ]
        , div [ class "sixteen wide mobile twelve wide tablet twelve wide computer column" ]
            [ div [ class "" ]
                (case model.currentTab of
                    Just SourceTab ->
                        viewSources flags settings model

                    Just UserTab ->
                        viewUsers settings model

                    Just InsightsTab ->
                        viewInsights flags model

                    Just SettingsTab ->
                        viewSettings flags settings model

                    Nothing ->
                        []
                )
            ]
        ]


viewInsights : Flags -> Model -> List (Html Msg)
viewInsights flags model =
    let
        ( coll, user ) =
            Maybe.map (\a -> ( a.collective, a.user )) flags.account
                |> Maybe.withDefault ( "", "" )
    in
    [ h1 [ class "ui header" ]
        [ i [ class "chart bar outline icon" ] []
        , div [ class "content" ]
            [ text "Insights"
            ]
        ]
    , h2 [ class "ui sub header" ]
        [ div [ class "ui horizontal list" ]
            [ div
                [ class "item"
                , title "Collective"
                ]
                [ i [ class "users circle icon" ] []
                , text coll
                ]
            , div
                [ class "item"
                , title "User"
                ]
                [ i [ class "user outline icon" ] []
                , text user
                ]
            ]
        ]
    , div [ class "ui basic blue segment" ]
        [ h4 [ class "ui header" ]
            [ text "Items"
            ]
        , div [ class "ui statistics" ]
            [ div [ class "ui statistic" ]
                [ div [ class "value" ]
                    [ String.fromInt (model.insights.incomingCount + model.insights.outgoingCount) |> text
                    ]
                , div [ class "label" ]
                    [ text "Items"
                    ]
                ]
            , div [ class "ui statistic" ]
                [ div [ class "value" ]
                    [ String.fromInt model.insights.incomingCount |> text
                    ]
                , div [ class "label" ]
                    [ text "Incoming"
                    ]
                ]
            , div [ class "ui statistic" ]
                [ div [ class "value" ]
                    [ String.fromInt model.insights.outgoingCount |> text
                    ]
                , div [ class "label" ]
                    [ text "Outgoing"
                    ]
                ]
            ]
        ]
    , div [ class "ui basic blue segment" ]
        [ h4 [ class "ui header" ]
            [ text "Size"
            ]
        , div [ class "ui statistics" ]
            [ div [ class "ui statistic" ]
                [ div [ class "value" ]
                    [ toFloat model.insights.itemSize |> Util.Size.bytesReadable Util.Size.B |> text
                    ]
                , div [ class "label" ]
                    [ text "Size"
                    ]
                ]
            ]
        ]
    , div [ class "ui basic blue segment" ]
        [ h4 [ class "ui header" ]
            [ text "Tags"
            ]
        , div [ class "ui statistics" ]
            (List.map makeTagStats
                (List.sortBy .count model.insights.tagCloud.items
                    |> List.reverse
                )
            )
        ]
    ]


makeTagStats : TagCount -> Html Msg
makeTagStats nc =
    div [ class "ui statistic" ]
        [ div [ class "value" ]
            [ String.fromInt nc.count |> text
            ]
        , div [ class "label" ]
            [ text nc.tag.name
            ]
        ]


viewSources : Flags -> UiSettings -> Model -> List (Html Msg)
viewSources flags settings model =
    [ h2 [ class "ui header" ]
        [ Icons.sourceIcon ""
        , div [ class "content" ]
            [ text "Sources"
            ]
        ]
    , Html.map SourceMsg (Comp.SourceManage.view flags settings model.sourceModel)
    ]


viewUsers : UiSettings -> Model -> List (Html Msg)
viewUsers settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui user icon" ] []
        , div [ class "content" ]
            [ text "Users"
            ]
        ]
    , Html.map UserMsg (Comp.UserManage.view settings model.userModel)
    ]


viewSettings : Flags -> UiSettings -> Model -> List (Html Msg)
viewSettings flags settings model =
    [ h2 [ class "ui header" ]
        [ i [ class "cog icon" ] []
        , text "Collective Settings"
        ]
    , div [ class "ui segment" ]
        [ Html.map SettingsFormMsg
            (Comp.CollectiveSettingsForm.view flags settings model.settingsModel)
        ]
    , div
        [ classList
            [ ( "ui message", True )
            , ( "hidden", Util.Maybe.isEmpty model.submitResult )
            , ( "success", Maybe.map .success model.submitResult |> Maybe.withDefault False )
            , ( "error", Maybe.map .success model.submitResult |> Maybe.map not |> Maybe.withDefault False )
            ]
        ]
        [ Maybe.map .message model.submitResult
            |> Maybe.withDefault ""
            |> text
        ]
    ]
