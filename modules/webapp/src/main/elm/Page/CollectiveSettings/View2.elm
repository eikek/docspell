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
import Page.CollectiveSettings.Data exposing (..)
import Styles as S
import Util.Maybe
import Util.Size


viewSidebar : Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar visible _ _ model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ div [ class "" ]
            [ h1 [ class S.header1 ]
                [ text "Collective Settings"
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
                    [ text "Insights" ]
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
                    [ text "Sources" ]
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
                    [ text "Settings" ]
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
                    [ text "Users" ]
                ]
            ]
        ]


viewContent : Flags -> UiSettings -> Model -> Html Msg
viewContent flags settings model =
    div
        [ id "content"
        , class S.content
        ]
        (case model.currentTab of
            Just UserTab ->
                viewUsers settings model

            Just SettingsTab ->
                viewSettings flags settings model

            Just InsightsTab ->
                viewInsights flags model

            Just SourceTab ->
                viewSources flags settings model

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


viewInsights : Flags -> Model -> List (Html Msg)
viewInsights flags model =
    let
        ( coll, user ) =
            Maybe.map (\a -> ( a.collective, a.user )) flags.account
                |> Maybe.withDefault ( "", "" )
    in
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-chart-bar font-thin" ] []
        , span [ class "ml-2" ]
            [ text "Insights"
            ]
        ]
    , div [ class "mb-4" ]
        [ hr [ class S.border ] []
        ]
    , h2 [ class S.header3 ]
        [ div [ class "flex flex-row space-x-6" ]
            [ div
                [ class ""
                , title "Collective"
                ]
                [ i [ class "fa fa-users" ] []
                , span [ class "ml-2" ]
                    [ text coll
                    ]
                ]
            , div
                [ class ""
                , title "User"
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
            [ text "Items"
            ]
        , div [ class "flex px-4 flex-wrap" ]
            [ stats (String.fromInt (model.insights.incomingCount + model.insights.outgoingCount)) "Items"
            , stats (String.fromInt model.insights.incomingCount) "Incoming"
            , stats (String.fromInt model.insights.outgoingCount) "Outgoing"
            ]
        ]
    , div
        [ class "py-2"
        ]
        [ h4 [ class S.header3 ]
            [ text "Size"
            ]
        , div [ class "flex px-4 flex-wrap" ]
            [ stats (toFloat model.insights.itemSize |> Util.Size.bytesReadable Util.Size.B) "Size"
            ]
        ]
    , div
        [ class "py-2"
        ]
        [ h4 [ class S.header3 ]
            [ text "Tags"
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


viewSources : Flags -> UiSettings -> Model -> List (Html Msg)
viewSources flags settings model =
    [ h1
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.sourceIcon2 ""
        , div [ class "ml-3" ]
            [ text "Sources"
            ]
        ]
    , Html.map SourceMsg (Comp.SourceManage.view2 flags settings model.sourceModel)
    ]


viewUsers : UiSettings -> Model -> List (Html Msg)
viewUsers settings model =
    [ h1
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-user" ] []
        , div [ class "ml-3" ]
            [ text "Users"
            ]
        ]
    , Html.map UserMsg (Comp.UserManage.view2 settings model.userModel)
    ]


viewSettings : Flags -> UiSettings -> Model -> List (Html Msg)
viewSettings flags settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-cog" ] []
        , span [ class "ml-3" ]
            [ text "Collective Settings"
            ]
        ]
    , Html.map SettingsFormMsg
        (Comp.CollectiveSettingsForm.view2 flags settings model.settingsModel)
    , div
        [ classList
            [ ( "hidden", Util.Maybe.isEmpty model.submitResult )
            , ( S.successMessage, Maybe.map .success model.submitResult |> Maybe.withDefault False )
            , ( S.errorMessage, Maybe.map .success model.submitResult |> Maybe.map not |> Maybe.withDefault False )
            ]
        , class "mt-2"
        ]
        [ Maybe.map .message model.submitResult
            |> Maybe.withDefault ""
            |> text
        ]
    ]
