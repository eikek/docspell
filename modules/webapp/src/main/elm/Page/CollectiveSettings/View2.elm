{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Page.CollectiveSettings.View2 exposing (viewContent, viewSidebar)

import Api.Model.TagCount exposing (TagCount)
import Comp.Basic as B
import Comp.CollectiveSettingsForm
import Comp.SourceManage
import Comp.UserManage
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Page.CollectiveSettings exposing (Texts)
import Page.CollectiveSettings.Data exposing (..)
import Styles as S
import Util.Size


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible _ _ model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ div [ class "" ]
            [ h1 [ class S.header1 ]
                [ text texts.collectiveSettings
                ]
            ]
        , div [ class "flex flex-col my-2" ]
            [ a
                [ href "#"
                , onClick (SetTab InsightsTab)
                , menuEntryActive model InsightsTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-chart-bar" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.insights ]
                ]
            , a
                [ href "#"
                , onClick (SetTab SourceTab)
                , class S.sidebarLink
                , menuEntryActive model SourceTab
                ]
                [ Icons.sourceIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text texts.sources ]
                ]
            , a
                [ href "#"
                , onClick (SetTab SettingsTab)
                , menuEntryActive model SettingsTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-cog" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.settings ]
                ]
            , a
                [ href "#"
                , onClick (SetTab UserTab)
                , menuEntryActive model UserTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-user" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.users ]
                ]
            ]
        ]


viewContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts flags settings model =
    div
        [ id "content"
        , class S.content
        ]
        (case model.currentTab of
            Just UserTab ->
                viewUsers texts settings model

            Just SettingsTab ->
                viewSettings texts flags settings model

            Just InsightsTab ->
                viewInsights texts flags model

            Just SourceTab ->
                viewSources texts flags settings model

            Nothing ->
                []
        )



--- Helper


menuEntryActive : Model -> Tab -> Attribute msg
menuEntryActive model tab =
    if model.currentTab == Just tab then
        class S.sidebarMenuItemActive

    else
        class ""


viewInsights : Texts -> Flags -> Model -> List (Html Msg)
viewInsights texts flags model =
    let
        ( coll, user ) =
            Maybe.map (\a -> ( a.collective, a.user )) flags.account
                |> Maybe.withDefault ( "", "" )
    in
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-chart-bar font-thin" ] []
        , span [ class "ml-2" ]
            [ text texts.insights
            ]
        ]
    , div [ class "mb-4" ]
        [ hr [ class S.border ] []
        ]
    , h2 [ class S.header3 ]
        [ div [ class "flex flex-row space-x-6" ]
            [ div
                [ class ""
                , title texts.collective
                ]
                [ i [ class "fa fa-users" ] []
                , span [ class "ml-2" ]
                    [ text coll
                    ]
                ]
            , div
                [ class ""
                , title texts.user
                ]
                [ i [ class "fa fa-user font-thin" ] []
                , span [ class "ml-2" ]
                    [ text user
                    ]
                ]
            ]
        ]
    , div
        [ class "py-2"
        ]
        [ h4 [ class S.header3 ]
            [ text texts.items
            ]
        , div [ class "flex px-4 flex-wrap" ]
            [ stats (String.fromInt (model.insights.incomingCount + model.insights.outgoingCount)) texts.basics.items
            , stats (String.fromInt model.insights.incomingCount) texts.basics.incoming
            , stats (String.fromInt model.insights.outgoingCount) texts.basics.outgoing
            ]
        ]
    , div
        [ class "py-2"
        ]
        [ h4 [ class S.header3 ]
            [ text texts.size
            ]
        , div [ class "flex px-4 flex-wrap" ]
            [ stats (toFloat model.insights.itemSize |> Util.Size.bytesReadable Util.Size.B) texts.size
            ]
        ]
    , div
        [ class "py-2"
        ]
        [ h4 [ class S.header3 ]
            [ text texts.basics.tags
            ]
        , div [ class "flex px-4 flex-wrap" ]
            (List.map makeTagStats
                (List.sortBy .count model.insights.tagCloud.items
                    |> List.reverse
                )
            )
        ]
    ]


stats : String -> String -> Html msg
stats value label =
    B.stats
        { rootClass = "mb-4"
        , valueClass = "text-6xl"
        , value = value
        , label = label
        }


makeTagStats : TagCount -> Html Msg
makeTagStats nc =
    stats (String.fromInt nc.count) nc.tag.name


viewSources : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewSources texts flags settings model =
    [ h1
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.sourceIcon2 ""
        , div [ class "ml-3" ]
            [ text texts.sources
            ]
        ]
    , Html.map SourceMsg (Comp.SourceManage.view2 texts.sourceManage flags settings model.sourceModel)
    ]


viewUsers : Texts -> UiSettings -> Model -> List (Html Msg)
viewUsers texts settings model =
    [ h1
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-user" ] []
        , div [ class "ml-3" ]
            [ text texts.users
            ]
        ]
    , Html.map UserMsg (Comp.UserManage.view2 texts.userManage settings model.userModel)
    ]


viewSettings : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewSettings texts flags settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-cog" ] []
        , span [ class "ml-3" ]
            [ text texts.collectiveSettings
            ]
        ]
    , div
        [ classList
            [ ( "hidden", model.formState == InitialState )
            , ( S.successMessage, model.formState == SubmitSuccessful )
            , ( S.errorMessage, model.formState /= SubmitSuccessful )
            ]
        , class "mb-2"
        ]
        [ case model.formState of
            SubmitSuccessful ->
                text texts.submitSuccessful

            SubmitError err ->
                text (texts.httpError err)

            SubmitFailed m ->
                text m

            InitialState ->
                text ""
        ]
    , Html.map SettingsFormMsg
        (Comp.CollectiveSettingsForm.view2
            flags
            texts.collectiveSettingsForm
            settings
            model.settingsModel
        )
    ]
