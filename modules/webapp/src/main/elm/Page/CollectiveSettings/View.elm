module Page.CollectiveSettings.View exposing (view)

import Api.Model.NameCount exposing (NameCount)
import Comp.CollectiveSettingsForm
import Comp.SourceManage
import Comp.UserManage
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page.CollectiveSettings.Data exposing (..)
import Util.Html exposing (classActive)
import Util.Maybe
import Util.Size


view : Flags -> Model -> Html Msg
view flags model =
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
                        [ i [ class "upload icon" ] []
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
                        viewSources flags model

                    Just UserTab ->
                        viewUsers model

                    Just InsightsTab ->
                        viewInsights model

                    Just SettingsTab ->
                        viewSettings flags model

                    Nothing ->
                        []
                )
            ]
        ]


viewInsights : Model -> List (Html Msg)
viewInsights model =
    [ h1 [ class "ui header" ]
        [ i [ class "chart bar outline icon" ] []
        , div [ class "content" ]
            [ text "Insights"
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
            (List.map makeTagStats model.insights.tagCloud.items)
        ]
    ]


makeTagStats : NameCount -> Html Msg
makeTagStats nc =
    div [ class "ui statistic" ]
        [ div [ class "value" ]
            [ String.fromInt nc.count |> text
            ]
        , div [ class "label" ]
            [ text nc.name
            ]
        ]


viewSources : Flags -> Model -> List (Html Msg)
viewSources flags model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui upload icon" ] []
        , div [ class "content" ]
            [ text "Sources"
            ]
        ]
    , Html.map SourceMsg (Comp.SourceManage.view flags model.sourceModel)
    ]


viewUsers : Model -> List (Html Msg)
viewUsers model =
    [ h2 [ class "ui header" ]
        [ i [ class "ui user icon" ] []
        , div [ class "content" ]
            [ text "Users"
            ]
        ]
    , Html.map UserMsg (Comp.UserManage.view model.userModel)
    ]


viewSettings : Flags -> Model -> List (Html Msg)
viewSettings flags model =
    [ h2 [ class "ui header" ]
        [ i [ class "cog icon" ] []
        , text "Settings"
        ]
    , div [ class "ui segment" ]
        [ Html.map SettingsFormMsg (Comp.CollectiveSettingsForm.view flags model.settingsModel)
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
