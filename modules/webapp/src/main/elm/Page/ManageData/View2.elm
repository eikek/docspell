module Page.ManageData.View2 exposing (viewContent, viewSidebar)

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
import Page.ManageData.Data exposing (..)
import Styles as S


viewSidebar : Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar visible _ settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ div [ class "" ]
            [ h1 [ class S.header1 ]
                [ text "Manage Data"
                ]
            ]
        , div [ class "flex flex-col my-2" ]
            [ a
                [ href "#"
                , onClick (SetTab TagTab)
                , class S.sidebarLink
                , menuEntryActive model TagTab
                ]
                [ Icons.tagIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text "Tags" ]
                ]
            , a
                [ href "#"
                , onClick (SetTab EquipTab)
                , menuEntryActive model EquipTab
                , class S.sidebarLink
                ]
                [ Icons.equipmentIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text "Equipment" ]
                ]
            , a
                [ href "#"
                , onClick (SetTab OrgTab)
                , menuEntryActive model OrgTab
                , class S.sidebarLink
                ]
                [ Icons.organizationIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text "Organization" ]
                ]
            , a
                [ href "#"
                , onClick (SetTab PersonTab)
                , menuEntryActive model PersonTab
                , class S.sidebarLink
                ]
                [ Icons.personIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text "Person" ]
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
                [ Icons.folderIcon2 ""
                , span
                    [ class "ml-3" ]
                    [ text "Folder" ]
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
                    [ text "Custom Fields" ]
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
            Just TagTab ->
                viewTags model

            Just EquipTab ->
                viewEquip model

            Just OrgTab ->
                viewOrg settings model

            Just PersonTab ->
                viewPerson settings model

            Just FolderTab ->
                viewFolder flags settings model

            Just CustomFieldTab ->
                viewCustomFields flags settings model

            Nothing ->
                []
        )


menuEntryActive : Model -> Tab -> Attribute msg
menuEntryActive model tab =
    if model.currentTab == Just tab then
        class S.sidebarMenuItemActive

    else
        class ""


viewTags : Model -> List (Html Msg)
viewTags model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.tagIcon2 ""
        , div [ class "ml-2" ]
            [ text "Tags"
            ]
        ]
    , Html.map TagManageMsg (Comp.TagManage.view2 model.tagManageModel)
    ]


viewEquip : Model -> List (Html Msg)
viewEquip model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.equipmentIcon2 ""
        , div [ class "ml-2" ]
            [ text "Equipment"
            ]
        ]
    , Html.map EquipManageMsg (Comp.EquipmentManage.view2 model.equipManageModel)
    ]


viewOrg : UiSettings -> Model -> List (Html Msg)
viewOrg settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.organizationIcon2 ""
        , div [ class "ml-2" ]
            [ text "Organizations"
            ]
        ]
    , Html.map OrgManageMsg (Comp.OrgManage.view2 settings model.orgManageModel)
    ]


viewPerson : UiSettings -> Model -> List (Html Msg)
viewPerson settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.personIcon2 ""
        , div [ class "ml-2" ]
            [ text "Person"
            ]
        ]
    , Html.map PersonManageMsg
        (Comp.PersonManage.view2 settings model.personManageModel)
    ]


viewFolder : Flags -> UiSettings -> Model -> List (Html Msg)
viewFolder flags _ model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.folderIcon2 ""
        , div
            [ class "ml-2"
            ]
            [ text "Folder"
            ]
        ]
    , Html.map FolderMsg
        (Comp.FolderManage.view2 flags model.folderManageModel)
    ]


viewCustomFields : Flags -> UiSettings -> Model -> List (Html Msg)
viewCustomFields flags _ model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ Icons.customFieldIcon2 ""
        , div [ class "ml-2" ]
            [ text "Custom Fields"
            ]
        ]
    , Html.map CustomFieldMsg
        (Comp.CustomFieldManage.view2 flags model.fieldManageModel)
    ]
