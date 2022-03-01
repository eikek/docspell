{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module App.View2 exposing (view)

import Api.Model.AuthResult exposing (AuthResult)
import App.Data exposing (..)
import Comp.Basic as B
import Data.Environment as Env
import Data.Flags
import Data.Icons as Icons
import Data.UiSettings
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages exposing (Messages)
import Messages.App exposing (Texts)
import Messages.UiLanguage
import Page exposing (Page(..))
import Page.CollectiveSettings.View2 as CollectiveSettings
import Page.Dashboard.View as Dashboard
import Page.ItemDetail.View2 as ItemDetail
import Page.Login.View2 as Login
import Page.ManageData.View2 as ManageData
import Page.NewInvite.View2 as NewInvite
import Page.Queue.View2 as Queue
import Page.Register.View2 as Register
import Page.Search.Data
import Page.Search.View2 as Search
import Page.Share.View as Share
import Page.ShareDetail.View as ShareDetail
import Page.Upload.View2 as Upload
import Page.UserSettings.View2 as UserSettings
import Styles as S


view : Model -> List (Html Msg)
view model =
    [ topNavbar model
    , mainContent model
    ]


topNavbar : Model -> Html Msg
topNavbar model =
    case Data.Flags.getAccount model.flags of
        Just acc ->
            topNavUser acc model

        Nothing ->
            topNavAnon model


topNavUser : AuthResult -> Model -> Html Msg
topNavUser auth model =
    let
        texts =
            Messages.get (App.Data.getUiLanguage model) model.uiSettings.timeZone
    in
    nav
        [ id "top-nav"
        , class styleTopNav
        ]
        [ B.genericButton
            { label = ""
            , icon = "fa fa-bars"
            , handler = onClick ToggleSidebar
            , disabled = not (Page.hasSidebar model.page)
            , attrs = [ href "#" ]
            , baseStyle = "font-bold inline-flex items-center px-4 py-2"
            , activeStyle = "hover:bg-blue-200 dark:hover:bg-slate-800 w-12"
            }
        , headerNavItem True model
        , div [ class "flex flex-grow justify-center" ]
            [ a
                [ class S.infoMessageBase
                , class "my-2 px-1 py-1 rounded-lg inline-block hover:opacity-50"
                , classList [ ( "hidden", not model.showNewItemsArrived ) ]
                , if Page.isSearchPage model.page || Page.isDashboardPage model.page then
                    href "#"

                  else
                    Page.href (SearchPage Nothing)
                , onClick ToggleShowNewItemsArrived
                ]
                [ i [ class "fa fa-exclamation-circle mr-1" ] []
                , text texts.app.newItemsArrived
                ]
            ]
        , div [ class "flex justify-end" ]
            [ userMenu texts.app auth model
            , dataMenu texts.app auth model
            ]
        ]


topNavAnon : Model -> Html Msg
topNavAnon model =
    nav
        [ id "top-nav"
        , class styleTopNav
        ]
        [ B.genericButton
            { label = ""
            , icon = "fa fa-bars"
            , handler = onClick ToggleSidebar
            , disabled = not (Page.hasSidebar model.page)
            , attrs = [ href "#" ]
            , baseStyle = "font-bold inline-flex items-center px-4 py-2"
            , activeStyle = "hover:bg-blue-200 dark:hover:bg-slate-800 w-12"
            }
        , headerNavItem False model
        , div [ class "flex flex-grow justify-end" ]
            [ langMenu model
            , a
                [ href "#"
                , onClick ToggleDarkMode
                , class dropdownLink
                ]
                [ i [ class "fa fa-adjust w-6" ] []
                ]
            ]
        ]


headerNavItem : Bool -> Model -> Html Msg
headerNavItem authenticated model =
    let
        tag =
            if authenticated then
                a

            else
                div
    in
    tag
        [ class "inline-flex font-bold items-center px-4"
        , classList [ ( "hover:bg-blue-200 dark:hover:bg-slate-800", authenticated ) ]
        , if authenticated then
            Page.href DashboardPage

          else
            href "#"
        ]
        [ img
            [ src (model.flags.config.docspellAssetPath ++ "/img/logo-96.png")
            , class "w-9 h-9 mr-2 block"
            ]
            []
        , div [ class "" ]
            [ text "Docspell"
            ]
        ]


mainContent : Model -> Html Msg
mainContent model =
    let
        texts =
            Messages.get (App.Data.getUiLanguage model) model.uiSettings.timeZone
    in
    div
        [ id "main"
        , class styleMain
        ]
        (case model.page of
            DashboardPage ->
                viewDashboard texts model

            SearchPage bmId ->
                viewSearch texts bmId model

            CollectiveSettingPage ->
                viewCollectiveSettings texts model

            LoginPage _ ->
                viewLogin texts model

            ManageDataPage ->
                viewManageData texts model

            UserSettingPage ->
                viewUserSettings texts model

            QueuePage ->
                viewQueue texts model

            RegisterPage ->
                viewRegister texts model

            UploadPage mid ->
                viewUpload texts mid model

            NewInvitePage ->
                viewNewInvite texts model

            ItemDetailPage id ->
                viewItemDetail texts id model

            SharePage id ->
                viewShare texts id model

            ShareDetailPage shareId itemId ->
                viewShareDetail texts shareId itemId model
        )



--- Helpers


styleTopNav : String
styleTopNav =
    "top-0 fixed z-50 w-full flex flex-row justify-start shadow-sm h-12 bg-blue-100 dark:bg-slate-900 text-gray-800 dark:text-slate-200 antialiased"


styleMain : String
styleMain =
    "mt-12 flex md:flex-row flex-col w-full h-screen-12 overflow-y-hidden bg-white dark:bg-slate-800 text-gray-800 dark:text-slate-300 antialiased"


langMenu : Model -> Html Msg
langMenu model =
    let
        texts =
            Messages.get (App.Data.getUiLanguage model) model.uiSettings.timeZone

        langItem lang =
            let
                langMsg =
                    Messages.get lang model.uiSettings.timeZone
            in
            a
                [ classList
                    [ ( dropdownItem, True )
                    , ( "bg-gray-200 dark:bg-slate-700", lang == texts.lang )
                    ]
                , onClick (SetLanguage lang)
                , href "#"
                ]
                [ i [ langMsg |> .flagIcon |> class ] []
                , span [ class "ml-2" ] [ text langMsg.label ]
                ]
    in
    div
        [ class "relative"
        , classList [ ( "hidden", List.length Messages.UiLanguage.all == 1 ) ]
        ]
        [ a
            [ class dropdownLink
            , onClick ToggleLangMenu
            , href "#"
            ]
            [ i [ class texts.flagIcon ] []
            ]
        , div
            [ class dropdownMenu
            , classList [ ( "hidden", not model.langMenuOpen ) ]
            ]
            (List.map langItem Messages.UiLanguage.all)
        ]


dataMenu : Texts -> AuthResult -> Model -> Html Msg
dataMenu texts _ model =
    div [ class "relative" ]
        [ a
            [ class dropdownLink
            , class "inline-block relative"
            , onClick ToggleNavMenu
            , href "#"
            ]
            [ i [ class "fa fa-cogs" ] []
            , div
                [ class "h-5 w-5 rounded-full text-xs px-1 py-1 absolute top-1 left-1 font-bold"
                , class "dark:bg-sky-500 dark:text-gray-200"
                , class "bg-blue-500 text-gray-50"
                , classList [ ( "hidden", model.jobsWaiting <= 0 ) ]
                ]
                [ div [ class "-mt-0.5 mx-auto text-center" ]
                    [ text (String.fromInt model.jobsWaiting)
                    ]
                ]
            ]
        , div
            [ class dropdownMenu
            , classList [ ( "hidden", not model.navMenuOpen ) ]
            ]
            [ dataPageLink model
                DashboardPage
                []
                [ img
                    [ class "w-4 inline-block"
                    , src (model.flags.config.docspellAssetPath ++ "/img/logo-mc-96.png")
                    ]
                    []
                , div [ class "inline-block ml-2" ]
                    [ text texts.dashboard
                    ]
                ]
            , div [ class "py-1" ] [ hr [ class S.border ] [] ]
            , dataPageLink model
                (SearchPage Nothing)
                []
                [ Icons.searchIcon "w-6"
                , span [ class "ml-1" ]
                    [ text texts.items
                    ]
                ]
            , dataPageLink model
                ManageDataPage
                []
                [ Icons.metadataIcon "w-6"
                , span [ class "ml-1" ]
                    [ text texts.manageData
                    ]
                ]
            , div [ class "divider" ] []
            , dataPageLink model
                (UploadPage Nothing)
                []
                [ Icons.fileUploadIcon "w-6"
                , span [ class "ml-1" ]
                    [ text texts.uploadFiles
                    ]
                ]
            , dataPageLink model
                QueuePage
                []
                [ i
                    [ if model.jobsWaiting <= 0 then
                        class "fa fa-tachometer-alt w-6"

                      else
                        class "fa fa-tachometer-alt w-6 animate-pulse dark:text-sky-500 text-blue-500"
                    ]
                    []
                , span [ class "ml-1" ]
                    [ text texts.processingQueue
                    ]
                ]
            , div
                [ classList
                    [ ( "py-1", True )
                    , ( "hidden", model.flags.config.signupMode /= "invite" )
                    ]
                ]
                [ hr [ class S.border ] [] ]
            , dataPageLink model
                NewInvitePage
                [ ( "hidden", model.flags.config.signupMode /= "invite" ) ]
                [ i [ class "fa fa-key w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.newInvites
                    ]
                ]
            , div [ class "py-1" ]
                [ hr [ class S.border ]
                    []
                ]
            , a
                [ class dropdownItem
                , href Data.UiSettings.documentationSite
                , target "_new"
                , title ("Opens " ++ Data.UiSettings.documentationSite)
                ]
                [ Icons.documentationIcon "w-6"
                , span [ class "ml-1" ] [ text texts.help ]
                , span [ class "float-right" ]
                    [ i [ class "fa fa-external-link-alt w-6" ] []
                    ]
                ]
            ]
        ]


userMenu : Texts -> AuthResult -> Model -> Html Msg
userMenu texts acc model =
    div [ class "relative" ]
        [ a
            [ class dropdownLink
            , onClick ToggleUserMenu
            , href "#"
            ]
            [ i [ class "fa fa-user w-6" ] []
            ]
        , div
            [ class dropdownMenu
            , classList [ ( "hidden", not model.userMenuOpen ) ]
            ]
            [ div [ class dropdownHeadItem ]
                [ i [ class "fa fa-user pr-2 font-thin" ] []
                , span [ class "ml-3 text-sm" ]
                    [ Data.Flags.accountString acc |> text
                    ]
                ]
            , div [ class "py-1" ] [ hr [ class S.border ] [] ]
            , userPageLink model
                CollectiveSettingPage
                [ i [ class "fa fa-users w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.collectiveProfile
                    ]
                ]
            , userPageLink model
                UserSettingPage
                [ i [ class "fa fa-user-circle w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.userProfile
                    ]
                ]
            , a
                [ href "#"
                , onClick ToggleDarkMode
                , class dropdownItem
                ]
                [ i [ class "fa fa-adjust w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.lightDark
                    ]
                ]
            , div [ class "py-1" ] [ hr [ class S.border ] [] ]
            , a
                [ href "#"
                , class dropdownItem
                , onClick Logout
                ]
                [ i [ class "fa fa-sign-out-alt w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.logout
                    ]
                ]
            ]
        ]


userPageLink : Model -> Page -> List (Html Msg) -> Html Msg
userPageLink model page children =
    a
        [ classList
            [ ( dropdownItem, True )
            , ( "bg-gray-200 dark:bg-slate-700", model.page == page )
            ]
        , onClick ToggleUserMenu
        , Page.href page
        ]
        children


dataPageLink : Model -> Page -> List ( String, Bool ) -> List (Html Msg) -> Html Msg
dataPageLink model page classes children =
    a
        [ classList
            ([ ( dropdownItem, True )
             , ( "bg-gray-200 dark:bg-slate-700", model.page == page )
             ]
                ++ classes
            )
        , onClick ToggleNavMenu
        , Page.href page
        ]
        children


dropdownLink : String
dropdownLink =
    "px-4 py-2 w-12 font-bold inline-flex h-full items-center hover:bg-blue-200 dark:hover:bg-slate-800"


dropdownItem : String
dropdownItem =
    "transition-colors duration-200 items-center block px-4 py-2 text-normal hover:bg-gray-200 dark:hover:bg-slate-700 dark:hover:text-slate-50"


dropdownHeadItem : String
dropdownHeadItem =
    "transition-colors duration-200 items-center block px-4 py-2 font-semibold uppercase"


dropdownMenu : String
dropdownMenu =
    " absolute right-0 bg-white dark:bg-slate-800 border dark:border-slate-700 dark:text-slate-300 shadow-lg opacity-1 transition duration-200 min-w-max "


modelEnv : Model -> Env.View
modelEnv model =
    { sidebarVisible = model.sidebarVisible
    , flags = model.flags
    , settings = model.uiSettings
    , selectedItems = model.selectedItems
    }


viewDashboard : Messages -> Model -> List (Html Msg)
viewDashboard texts model =
    [ Html.map DashboardMsg
        (Dashboard.viewSidebar texts.dashboard
            model.sidebarVisible
            model.flags
            model.version
            model.uiSettings
            model.dashboardModel
        )
    , Html.map DashboardMsg
        (Dashboard.viewContent texts.dashboard
            model.flags
            model.uiSettings
            model.dashboardModel
        )
    ]


viewShare : Messages -> String -> Model -> List (Html Msg)
viewShare texts shareId model =
    [ Html.map ShareMsg
        (Share.viewSidebar texts.share
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.shareModel
        )
    , Html.map ShareMsg
        (Share.viewContent texts.share
            model.flags
            model.version
            model.uiSettings
            shareId
            model.shareModel
        )
    ]


viewShareDetail : Messages -> String -> String -> Model -> List (Html Msg)
viewShareDetail texts shareId itemId model =
    [ Html.map ShareDetailMsg
        (ShareDetail.viewSidebar texts.shareDetail
            model.sidebarVisible
            model.flags
            model.uiSettings
            shareId
            itemId
            model.shareDetailModel
        )
    , Html.map ShareDetailMsg
        (ShareDetail.viewContent texts.shareDetail
            model.flags
            model.uiSettings
            model.version
            shareId
            itemId
            model.shareDetailModel
        )
    ]


viewSearch : Messages -> Maybe String -> Model -> List (Html Msg)
viewSearch texts bmId model =
    let
        env =
            modelEnv model
    in
    [ Html.map SearchMsg
        (Search.viewSidebar texts.search
            env
            model.searchModel
        )
    , Html.map SearchMsg
        (Search.viewContent texts.search
            env
            model.searchModel
        )
    ]


viewCollectiveSettings : Messages -> Model -> List (Html Msg)
viewCollectiveSettings texts model =
    [ Html.map CollSettingsMsg
        (CollectiveSettings.viewSidebar texts.collectiveSettings
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.collSettingsModel
        )
    , Html.map CollSettingsMsg
        (CollectiveSettings.viewContent texts.collectiveSettings
            model.flags
            model.uiSettings
            model.collSettingsModel
        )
    ]


viewLogin : Messages -> Model -> List (Html Msg)
viewLogin texts model =
    [ Html.map LoginMsg
        (Login.viewSidebar model.sidebarVisible model.flags model.uiSettings model.loginModel)
    , Html.map LoginMsg
        (Login.viewContent texts.login model.flags model.version model.uiSettings model.loginModel)
    ]


viewManageData : Messages -> Model -> List (Html Msg)
viewManageData texts model =
    [ Html.map ManageDataMsg
        (ManageData.viewSidebar texts.manageData
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.manageDataModel
        )
    , Html.map ManageDataMsg
        (ManageData.viewContent texts.manageData
            model.flags
            model.uiSettings
            model.manageDataModel
        )
    ]


viewUserSettings : Messages -> Model -> List (Html Msg)
viewUserSettings texts model =
    [ Html.map UserSettingsMsg
        (UserSettings.viewSidebar texts.userSettings
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.userSettingsModel
        )
    , Html.map UserSettingsMsg
        (UserSettings.viewContent texts.userSettings
            model.flags
            model.uiSettings
            model.userSettingsModel
        )
    ]


viewQueue : Messages -> Model -> List (Html Msg)
viewQueue texts model =
    [ Html.map QueueMsg
        (Queue.viewSidebar texts.queue
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.queueModel
        )
    , Html.map QueueMsg
        (Queue.viewContent texts.queue model.flags model.uiSettings model.queueModel)
    ]


viewRegister : Messages -> Model -> List (Html Msg)
viewRegister texts model =
    [ Html.map RegisterMsg
        (Register.viewSidebar model.sidebarVisible model.flags model.uiSettings model.registerModel)
    , Html.map RegisterMsg
        (Register.viewContent texts.register model.flags model.uiSettings model.registerModel)
    ]


viewNewInvite : Messages -> Model -> List (Html Msg)
viewNewInvite texts model =
    [ Html.map NewInviteMsg
        (NewInvite.viewSidebar model.sidebarVisible model.flags model.uiSettings model.newInviteModel)
    , Html.map NewInviteMsg
        (NewInvite.viewContent texts.newInvite model.flags model.uiSettings model.newInviteModel)
    ]


viewUpload : Messages -> Maybe String -> Model -> List (Html Msg)
viewUpload texts mid model =
    [ Html.map UploadMsg
        (Upload.viewSidebar
            mid
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.uploadModel
        )
    , Html.map UploadMsg
        (Upload.viewContent texts.upload
            mid
            model.flags
            model.uiSettings
            model.uploadModel
        )
    ]


viewItemDetail : Messages -> String -> Model -> List (Html Msg)
viewItemDetail texts id model =
    let
        inav =
            Page.Search.Data.itemNav id model.searchModel

        env =
            modelEnv model
    in
    [ Html.map ItemDetailMsg
        (ItemDetail.viewSidebar texts.itemDetail
            env
            model.itemDetailModel
        )
    , Html.map ItemDetailMsg
        (ItemDetail.viewContent texts.itemDetail
            inav
            env
            model.itemDetailModel
        )
    ]
