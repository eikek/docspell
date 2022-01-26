{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.View exposing (viewContent, viewSidebar)

import Comp.DashboardView
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.NotificationHookManage
import Comp.OrgManage
import Comp.PeriodicQueryTaskManage
import Comp.PersonManage
import Comp.ShareManage
import Comp.SourceManage
import Comp.TagManage
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Dashboard exposing (Texts)
import Page.Dashboard.Data exposing (..)
import Page.Dashboard.SideMenu as SideMenu
import Styles as S


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible _ settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ SideMenu.view texts settings model.sideMenu
        ]


viewContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts flags settings model =
    div
        [ id "content"
        , class S.content
        ]
        [ case model.content of
            Home m ->
                Html.map DashboardMsg
                    (Comp.DashboardView.view m)

            Webhook m ->
                viewHookManage texts settings m

            PeriodicQuery m ->
                viewPeriodicQuery texts settings m

            Source m ->
                viewSource texts flags settings m

            Share m ->
                viewShare texts flags settings m

            Organization m ->
                viewOrganization texts settings m

            Person m ->
                viewPerson texts settings m

            Equipment m ->
                viewEquipment texts m

            Tags m ->
                viewTags texts settings m

            Folder m ->
                viewFolder texts flags m
        ]



--- Helpers


viewFolder : Texts -> Flags -> Comp.FolderManage.Model -> Html Msg
viewFolder texts flags model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Folder"
            ]
        , Html.map FolderMsg <|
            Comp.FolderManage.view2 texts.folderManage flags model
        ]


viewTags : Texts -> UiSettings -> Comp.TagManage.Model -> Html Msg
viewTags texts settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Tags"
            ]
        , Html.map TagMsg <|
            Comp.TagManage.view2 texts.tagManage settings model
        ]


viewEquipment : Texts -> Comp.EquipmentManage.Model -> Html Msg
viewEquipment texts model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Equipment"
            ]
        , Html.map EquipmentMsg <|
            Comp.EquipmentManage.view2 texts.equipManage model
        ]


viewPerson : Texts -> UiSettings -> Comp.PersonManage.Model -> Html Msg
viewPerson texts settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Person"
            ]
        , Html.map PersonMsg <|
            Comp.PersonManage.view2 texts.personManage settings model
        ]


viewOrganization : Texts -> UiSettings -> Comp.OrgManage.Model -> Html Msg
viewOrganization texts settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Organizations"
            ]
        , Html.map OrganizationMsg <|
            Comp.OrgManage.view2 texts.organizationManage settings model
        ]


viewShare : Texts -> Flags -> UiSettings -> Comp.ShareManage.Model -> Html Msg
viewShare texts flags settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Shares"
            ]
        , Html.map ShareMsg <|
            Comp.ShareManage.view texts.shareManage settings flags model
        ]


viewSource : Texts -> Flags -> UiSettings -> Comp.SourceManage.Model -> Html Msg
viewSource texts flags settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Sources"
            ]
        , Html.map SourceMsg <|
            Comp.SourceManage.view2 texts.sourceManage flags settings model
        ]


viewPeriodicQuery : Texts -> UiSettings -> Comp.PeriodicQueryTaskManage.Model -> Html Msg
viewPeriodicQuery texts settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Periodic Queries"
            ]
        , Html.map PeriodicQueryMsg <|
            Comp.PeriodicQueryTaskManage.view texts.periodicQueryManage settings model
        ]


viewHookManage : Texts -> UiSettings -> Comp.NotificationHookManage.Model -> Html Msg
viewHookManage texts settings model =
    div []
        [ h1 [ class S.header1 ]
            [ text "Notification Hooks"
            ]
        , Html.map NotificationHookMsg <|
            Comp.NotificationHookManage.view texts.notificationHookManage settings model
        ]
