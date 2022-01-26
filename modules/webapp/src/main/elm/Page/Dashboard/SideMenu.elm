{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.SideMenu exposing (view)

import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.BookmarkChooser
import Data.AccountScope
import Data.Dashboard exposing (Dashboard)
import Data.Dashboards
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (Attribute, Html, a, div, h3, i, span, text)
import Html.Attributes exposing (class, classList, href, target, title)
import Html.Events exposing (onClick)
import Messages.Page.Dashboard exposing (Texts)
import Page exposing (Page(..))
import Page.Dashboard.Data exposing (Model, Msg(..), isDashboardDefault, isDashboardVisible, isHomeContent)
import Styles as S


view : Texts -> VersionInfo -> UiSettings -> Model -> Html Msg
view texts versionInfo _ model =
    div [ class "flex flex-col flex-grow" ]
        [ div [ class "mt-2" ]
            [ menuLink [ onClick SetDefaultDashboard, href "#" ] (Icons.dashboardIcon "") texts.dashboardLink
            , menuLink [ Page.href (SearchPage Nothing) ] (Icons.searchIcon "") texts.basics.items
            , menuLink [ onClick InitUpload, href "#" ] (Icons.fileUploadIcon "") texts.uploadFiles
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.bookmarks
            ]
        , div [ class "ml-2" ]
            [ Html.map BookmarkMsg
                (Comp.BookmarkChooser.viewWith
                    { showUser = True, showCollective = True, showShares = False }
                    texts.bookmarkChooser
                    model.sideMenu.bookmarkChooser
                    Comp.BookmarkChooser.emptySelection
                )
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.settings
            ]
        , div [ class "ml-2 mb-2" ]
            [ menuLink [ onClick InitNotificationHook, href "#" ] (Icons.notificationHooksIcon "") texts.basics.notificationHooks
            , menuLink [ onClick InitPeriodicQuery, href "#" ] (Icons.periodicTasksIcon "") texts.basics.periodicQueries
            , menuLink [ onClick InitSource, href "#" ] (Icons.sourceIcon2 "") texts.basics.sources
            , menuLink [ onClick InitShare, href "#" ] (Icons.shareIcon "") texts.basics.shares
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.manage
            ]
        , div [ class "ml-2 mb-2" ]
            [ menuLink [ onClick InitOrganization, href "#" ] (Icons.organizationIcon "") texts.basics.organization
            , menuLink [ onClick InitPerson, href "#" ] (Icons.personIcon "") texts.basics.person
            , menuLink [ onClick InitEquipment, href "#" ] (Icons.equipmentIcon "") texts.basics.equipment
            , menuLink [ onClick InitTags, href "#" ] (Icons.tagsIcon "") texts.basics.tags
            , menuLink [ onClick InitFolder, href "#" ] (Icons.folderIcon "") texts.basics.folder
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            , classList [ ( "hidden", Data.Dashboards.countAll model.dashboards <= 1 ) ]
            ]
            [ text texts.dashboards
            ]
        , div
            [ class "ml-2"
            , classList [ ( "hidden", Data.Dashboards.countAll model.dashboards <= 1 ) ]
            ]
            [ titleDiv <| texts.accountScope Data.AccountScope.User
            , div
                [ classList [ ( "hidden", Data.Dashboards.isEmpty model.dashboards.user ) ]
                ]
                (Data.Dashboards.map (dashboardLink texts model) model.dashboards.user)
            , titleDiv <| texts.accountScope Data.AccountScope.Collective
            , div
                [ classList [ ( "hidden", Data.Dashboards.isEmpty model.dashboards.collective ) ]
                ]
                (Data.Dashboards.map (dashboardLink texts model) model.dashboards.collective)
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.misc
            ]
        , div [ class "ml-2" ]
            [ menuLink
                [ onClick InitEditDashboard
                , classList [ ( "hidden", not (isHomeContent model.content) ) ]
                , href "#"
                ]
                (Icons.editIcon "")
                texts.editDashboard
            , div [ class "mt-2 opacity-75" ]
                [ menuLink [ href Data.UiSettings.documentationSite, target "_blank" ]
                    (Icons.documentationIcon "")
                    texts.documentation
                ]
            ]
        , div [ class "flex flex-grow items-end" ]
            [ div [ class "text-center text-xs w-full opacity-50" ]
                [ text "Docspell "
                , text versionInfo.version
                ]
            ]
        ]


titleDiv : String -> Html msg
titleDiv label =
    div [ class "text-sm opacity-75 py-0.5 italic" ]
        [ text label
        ]


menuLinkStyle : String
menuLinkStyle =
    "my-1 flex flex-row items-center rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"


menuLink : List (Attribute Msg) -> Html Msg -> String -> Html Msg
menuLink attrs icon label =
    a
        (attrs ++ [ class menuLinkStyle ])
        [ icon
        , span [ class "ml-2" ]
            [ text label
            ]
        ]


dashboardLink : Texts -> Model -> Dashboard -> Html Msg
dashboardLink texts model db =
    let
        ( visible, default ) =
            ( isDashboardVisible model db.name
            , isDashboardDefault model db.name
            )
    in
    a
        [ class menuLinkStyle
        , classList [ ( "italic", visible ) ]
        , href "#"
        , onClick (SetDashboard db)
        ]
        [ if visible then
            i [ class "fa fa-check mr-2" ] []

          else
            i [ class "fa fa-columns mr-2" ] []
        , div [ class "flex flex-row flex-grow space-x-1" ]
            [ div [ class "flex flex-grow" ]
                [ text db.name
                ]
            , div [ class "opacity-50" ]
                [ i
                    [ classList [ ( "hidden", not default ) ]
                    , class "fa fa-house-user"
                    , title texts.defaultDashboard.default
                    ]
                    []
                ]
            ]
        ]
