{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module App.View2 exposing (view)

import Api.Model.AuthResult exposing (AuthResult)
import App.Data exposing (..)
import Comp.Basic as B
import Data.Flags
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages exposing (Messages)
import Messages.App exposing (Texts)
import Messages.UiLanguage
import Page exposing (Page(..))
import Page.CollectiveSettings.View2 as CollectiveSettings
import Page.Home.Data
import Page.Home.View2 as Home
import Page.ItemDetail.View2 as ItemDetail
import Page.Login.View2 as Login
import Page.ManageData.View2 as ManageData
import Page.NewInvite.View2 as NewInvite
import Page.Queue.View2 as Queue
import Page.Register.View2 as Register
import Page.Share.View as Share
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
            Messages.get <| App.Data.getUiLanguage model
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
            , activeStyle = "hover:bg-blue-200 dark:hover:bg-bluegray-800 w-12"
            }
        , headerNavItem model
        , div [ class "flex flex-grow justify-end" ]
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
            , activeStyle = "hover:bg-blue-200 dark:hover:bg-bluegray-800 w-12"
            }
        , headerNavItem model
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


headerNavItem : Model -> Html Msg
headerNavItem model =
    a
        [ class "inline-flex font-bold hover:bg-blue-200 dark:hover:bg-bluegray-800 items-center px-4"
        , Page.href HomePage
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
            Messages.get <| App.Data.getUiLanguage model
    in
    div
        [ id "main"
        , class styleMain
        ]
        (case model.page of
            HomePage ->
                viewHome texts model

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
        )



--- Helpers


styleTopNav : String
styleTopNav =
    "top-0 fixed z-50 w-full flex flex-row justify-start shadow-sm h-12 bg-blue-100 dark:bg-bluegray-900 text-gray-800 dark:text-bluegray-200 antialiased"


styleMain : String
styleMain =
    "mt-12 flex md:flex-row flex-col w-full h-screen-12 overflow-y-hidden bg-white dark:bg-bluegray-800 text-gray-800 dark:text-bluegray-300 antialiased"


langMenu : Model -> Html Msg
langMenu model =
    let
        texts =
            Messages.get <| App.Data.getUiLanguage model

        langItem lang =
            let
                langMsg =
                    Messages.get lang
            in
            a
                [ classList
                    [ ( dropdownItem, True )
                    , ( "bg-gray-200 dark:bg-bluegray-700", lang == texts.lang )
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
            , onClick ToggleNavMenu
            , href "#"
            ]
            [ i [ class "fa fa-cogs" ] []
            ]
        , div
            [ class dropdownMenu
            , classList [ ( "hidden", not model.navMenuOpen ) ]
            ]
            [ dataPageLink model
                HomePage
                []
                [ img
                    [ class "w-4 inline-block"
                    , src (model.flags.config.docspellAssetPath ++ "/img/logo-mc-96.png")
                    ]
                    []
                , div [ class "inline-block ml-2" ]
                    [ text texts.items
                    ]
                ]
            , div [ class "py-1" ] [ hr [ class S.border ] [] ]
            , dataPageLink model
                ManageDataPage
                []
                [ i [ class "fa fa-cubes w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.manageData
                    ]
                ]
            , div [ class "divider" ] []
            , dataPageLink model
                (UploadPage Nothing)
                []
                [ i [ class "fa fa-upload w-6" ] []
                , span [ class "ml-1" ]
                    [ text texts.uploadFiles
                    ]
                ]
            , dataPageLink model
                QueuePage
                []
                [ i [ class "fa fa-tachometer-alt w-6" ] []
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
                , href "https://docspell.org/docs"
                , target "_new"
                , title "Opens https://docspell.org/docs"
                ]
                [ i [ class "fa fa-question-circle w-6" ] []
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
            , ( "bg-gray-200 dark:bg-bluegray-700", model.page == page )
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
             , ( "bg-gray-200 dark:bg-bluegray-700", model.page == page )
             ]
                ++ classes
            )
        , onClick ToggleNavMenu
        , Page.href page
        ]
        children


dropdownLink : String
dropdownLink =
    "px-4 py-2 w-12 font-bold inline-flex h-full items-center hover:bg-blue-200 dark:hover:bg-bluegray-800"


dropdownItem : String
dropdownItem =
    "transition-colors duration-200 items-center block px-4 py-2 text-normal hover:bg-gray-200 dark:hover:bg-bluegray-700 dark:hover:text-bluegray-50"


dropdownHeadItem : String
dropdownHeadItem =
    "transition-colors duration-200 items-center block px-4 py-2 font-semibold uppercase"


dropdownMenu : String
dropdownMenu =
    " absolute right-0 bg-white dark:bg-bluegray-800 border dark:border-bluegray-700 dark:text-bluegray-300 shadow-lg opacity-1 transition duration-200 min-w-max "


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
            model.uiSettings
            model.shareModel
        )
    ]


viewHome : Messages -> Model -> List (Html Msg)
viewHome texts model =
    [ Html.map HomeMsg
        (Home.viewSidebar texts.home
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.homeModel
        )
    , Html.map HomeMsg
        (Home.viewContent texts.home
            model.flags
            model.uiSettings
            model.homeModel
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
            Page.Home.Data.itemNav id model.homeModel
    in
    [ Html.map ItemDetailMsg
        (ItemDetail.viewSidebar texts.itemDetail
            model.sidebarVisible
            model.flags
            model.uiSettings
            model.itemDetailModel
        )
    , Html.map ItemDetailMsg
        (ItemDetail.viewContent texts.itemDetail
            inav
            model.flags
            model.uiSettings
            model.itemDetailModel
        )
    ]
