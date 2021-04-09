module Page.UserSettings.View2 exposing (viewContent, viewSidebar)

import Comp.ChangePasswordForm
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationManage
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Messages.Page.UserSettings exposing (Texts)
import Page.UserSettings.Data exposing (..)
import Styles as S


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
                [ text texts.userSettings
                ]
            ]
        , div [ class "flex flex-col my-2" ]
            [ a
                [ href "#"
                , onClick (SetTab UiSettingsTab)
                , menuEntryActive model UiSettingsTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-cog" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.uiSettings ]
                ]
            , a
                [ href "#"
                , onClick (SetTab NotificationTab)
                , menuEntryActive model NotificationTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-bullhorn" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.notifications ]
                ]
            , a
                [ href "#"
                , onClick (SetTab ScanMailboxTab)
                , menuEntryActive model ScanMailboxTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-envelope-open font-thin" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.scanMailbox ]
                ]
            , a
                [ href "#"
                , onClick (SetTab EmailSettingsTab)
                , class S.sidebarLink
                , menuEntryActive model EmailSettingsTab
                ]
                [ i [ class "fa fa-envelope" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.emailSettingSmtp ]
                ]
            , a
                [ href "#"
                , onClick (SetTab ImapSettingsTab)
                , menuEntryActive model ImapSettingsTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-envelope" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.emailSettingImap ]
                ]
            , a
                [ href "#"
                , onClick (SetTab ChangePassTab)
                , menuEntryActive model ChangePassTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-user-secret" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.changePassword ]
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
            Just ChangePassTab ->
                viewChangePassword texts model

            Just EmailSettingsTab ->
                viewEmailSettings texts settings model

            Just NotificationTab ->
                viewNotificationManage texts settings model

            Just ImapSettingsTab ->
                viewImapSettings texts settings model

            Just ScanMailboxTab ->
                viewScanMailboxManage texts flags settings model

            Just UiSettingsTab ->
                viewUiSettings texts flags settings model

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


viewChangePassword : Texts -> Model -> List (Html Msg)
viewChangePassword texts model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-user-secret" ] []
        , div [ class "ml-3" ]
            [ text texts.changePassword
            ]
        ]
    , Html.map ChangePassMsg
        (Comp.ChangePasswordForm.view2 texts.changePasswordForm
            model.changePassModel
        )
    ]


viewUiSettings : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewUiSettings texts flags settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-cog" ] []
        , span [ class "ml-3" ]
            [ text texts.uiSettings
            ]
        ]
    , p [ class "opacity-75 text-lg mb-4" ]
        [ text texts.uiSettingsInfo
        ]
    , Html.map UiSettingsMsg
        (Comp.UiSettingsManage.view2
            texts.uiSettingsManage
            flags
            settings
            ""
            model.uiSettingsModel
        )
    ]


viewEmailSettings : Texts -> UiSettings -> Model -> List (Html Msg)
viewEmailSettings texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-envelope" ] []
        , div [ class "ml-3" ]
            [ text texts.emailSettingSmtp
            ]
        ]
    , Html.map EmailSettingsMsg
        (Comp.EmailSettingsManage.view2
            texts.emailSettingsManage
            settings
            model.emailSettingsModel
        )
    ]


viewImapSettings : Texts -> UiSettings -> Model -> List (Html Msg)
viewImapSettings texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-envelope" ] []
        , div [ class "ml-3" ]
            [ text texts.emailSettingImap
            ]
        ]
    , Html.map ImapSettingsMsg
        (Comp.ImapSettingsManage.view2
            texts.imapSettingsManage
            settings
            model.imapSettingsModel
        )
    ]


viewNotificationManage : Texts -> UiSettings -> Model -> List (Html Msg)
viewNotificationManage texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-bullhorn" ] []
        , div [ class "ml-3" ]
            [ text texts.notifications
            ]
        ]
    , p [ class "opacity-80 text-lg mb-3" ]
        [ text texts.notificationInfoText
        ]
    , p [ class "opacity-80 text-lg mb-3" ]
        [ Markdown.toHtml [] texts.notificationRemindDaysInfo
        ]
    , Html.map NotificationMsg
        (Comp.NotificationManage.view2 texts.notificationManage
            settings
            model.notificationModel
        )
    ]


viewScanMailboxManage : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
viewScanMailboxManage texts flags settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-envelope-open font-thin" ] []
        , div [ class "ml-3" ]
            [ text texts.scanMailbox
            ]
        ]
    , p [ class "opacity-80 text-lg mb-3" ]
        [ text texts.scanMailboxInfo1
        ]
    , p [ class "opacity-80 text-lg mb-3 hidden" ]
        [ text texts.scanMailboxInfo2
        ]
    , Html.map ScanMailboxMsg
        (Comp.ScanMailboxManage.view2
            texts.scanMailboxManage
            flags
            settings
            model.scanMailboxModel
        )
    ]
