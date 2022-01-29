{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ManageData.View2 exposing (viewContent, viewSidebar)

import Comp.BookmarkManage
import Comp.CustomFieldManage
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.OrgManage
import Comp.PersonManage
import Comp.TagManage
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Page.ManageData exposing (Texts)
import Page.ManageData.Data exposing (..)
import Styles as S


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible _ settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ div [ class "" ]
            [ h1 [ class S.header1 ]
                [ text texts.manageData
                ]
            ]
        , div [ class "flex flex-col my-2" ]
            [ a
                [ href "#"
                , onClick (SetTab TagTab)
                , class S.sidebarLink
                , menuEntryActive model TagTab
                ]
                [ Icons.tagIcon ""
                , span
                    [ class "ml-3" ]
                    [ text texts.basics.tags
                    ]
                ]
            , a
                [ href "#"
                , onClick (SetTab EquipTab)
                , menuEntryActive model EquipTab
                , class S.sidebarLink
                ]
                [ Icons.equipmentIcon ""
                , span
                    [ class "ml-3" ]
                    [ text texts.basics.equipment
                    ]
                ]
            , a
                [ href "#"
                , onClick (SetTab OrgTab)
                , menuEntryActive model OrgTab
                , class S.sidebarLink
                ]
                [ Icons.organizationIcon ""
                , span
                    [ class "ml-3" ]
                    [ text texts.basics.organization
                    ]
                ]
            , a
                [ href "#"
                , onClick (SetTab PersonTab)
                , menuEntryActive model PersonTab
                , class S.sidebarLink
                ]
                [ Icons.personIcon ""
                , span
                    [ class "ml-3" ]
                    [ text texts.basics.person
                    ]
                ]
            , a
                [ href "#"
                , classList
                    [ ( "hidden"
                      , Data.UiSettings.fieldHidden settings Data.Fields.Folder
                      )
                    ]
                , onClick (SetTab FolderTab)
                , menuEntryActive model FolderTab
                , class S.sidebarLink
                ]
                [ Icons.folderIcon ""
                , span
                    [ class "ml-3" ]
                    [ text texts.basics.folder
                    ]
                ]
            , a
                [ href "#"
                , classList
                    [ ( "invisible hidden"
                      , Data.UiSettings.fieldHidden settings Data.Fields.CustomFields
                      )
                    ]
                , onClick (SetTab CustomFieldTab)
                , menuEntryActive model CustomFieldTab
                , class S.sidebarLink
                ]
                [ Icons.customFieldIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text texts.basics.customFields
                    ]
                ]
            , a
                [ href "#"
                , onClick (SetTab BookmarkTab)
                , menuEntryActive model BookmarkTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-bookmark" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.bookmarks
                    ]
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
            Just TagTab ->
                viewTags texts settings model

            Just EquipTab ->
                viewEquip texts model

            Just OrgTab ->
                viewOrg texts settings model

            Just PersonTab ->
                viewPerson texts settings model

            Just FolderTab ->
                viewFolder texts flags settings model

            Just CustomFieldTab ->
                viewCustomFields texts flags settings model

            Just BookmarkTab ->
                viewBookmarks texts flags settings model

            Nothing ->
                []
        )


menuEntryActive : Model -> Tab -> Attribute msg
menuEntryActive model tab =
    if model.currentTab == Just tab then
        class S.sidebarMenuItemActive

    else
        class ""


viewTags : Texts -> UiSettings -> Model -> List (Html Msg)
viewTags texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.tagIcon ""
        , div [ class "ml-2" ]
            [ text texts.basics.tags
            ]
        ]
    , Html.map TagManageMsg
        (Comp.TagManage.view2
            texts.tagManage
            settings
            model.tagManageModel
        )
    ]


viewEquip : Texts -> Model -> List (Html Msg)
viewEquip texts model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.equipmentIcon ""
        , div [ class "ml-2" ]
            [ text texts.basics.equipment
            ]
        ]
    , Html.map EquipManageMsg
        (Comp.EquipmentManage.view2 texts.equipmentManage
            model.equipManageModel
        )
    ]


viewOrg : Texts -> UiSettings -> Model -> List (Html Msg)
viewOrg texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.organizationIcon ""
        , div [ class "ml-2" ]
            [ text texts.basics.organization
            ]
        ]
    , Html.map OrgManageMsg
        (Comp.OrgManage.view2 texts.orgManage
            settings
            model.orgManageModel
        )
    ]


viewPerson : Texts -> UiSettings -> Model -> List (Html Msg)
viewPerson texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.personIcon ""
        , div [ class "ml-2" ]
            [ text texts.basics.person
            ]
        ]
    , Html.map PersonManageMsg
        (Comp.PersonManage.view2 texts.personManage
            settings
            model.personManageModel
        )
    ]


viewFolder : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewFolder texts flags _ model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.folderIcon ""
        , div
            [ class "ml-2"
            ]
            [ text texts.basics.folder
            ]
        ]
    , Html.map FolderMsg
        (Comp.FolderManage.view2 texts.folderManage flags model.folderManageModel)
    ]


viewCustomFields : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewCustomFields texts flags _ model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.customFieldIcon2 ""
        , div [ class "ml-2" ]
            [ text texts.basics.customFields
            ]
        ]
    , Html.map CustomFieldMsg
        (Comp.CustomFieldManage.view2 texts.customFieldManage
            flags
            model.fieldManageModel
        )
    ]


viewBookmarks : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewBookmarks texts flags settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-bookmark" ] []
        , div [ class "ml-2" ]
            [ text texts.bookmarks
            ]
        ]
    , Html.map BookmarkMsg (Comp.BookmarkManage.view texts.bookmarkManage settings flags model.bookmarkModel)
    ]
