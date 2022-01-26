{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.UserSettings.View2 exposing (viewContent, viewSidebar)

import Comp.ChangePasswordForm
import Comp.DueItemsTaskManage
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationChannelManage
import Comp.NotificationHookManage
import Comp.OtpSetup
import Comp.PeriodicQueryTaskManage
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.Flags exposing (Flags)
import Data.Icons as Icons
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
    let
        isNotificationTab =
            case model.currentTab of
                Just NotificationTab ->
                    True

                Just NotificationQueriesTab ->
                    True

                Just NotificationWebhookTab ->
                    True

                Just NotificationDueItemsTab ->
                    True

                _ ->
                    False
    in
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
            , div []
                [ a
                    [ href "#"
                    , onClick (SetTab NotificationTab)
                    , menuEntryActive model NotificationTab
                    , class S.sidebarLink
                    ]
                    [ Icons.notificationHooksIcon ""
                    , span
                        [ class "ml-3" ]
                        [ text texts.notifications ]
                    ]
                , div
                    [ class "ml-5 flex flex-col"
                    , classList [ ( "hidden", not isNotificationTab ) ]
                    ]
                    [ a
                        [ href "#"
                        , onClick (SetTab NotificationWebhookTab)
                        , menuEntryActive model NotificationWebhookTab
                        , class S.sidebarLink
                        ]
                        [ i [ class "fa fa-bell" ] []
                        , span
                            [ class "ml-3" ]
                            [ text texts.webhooks ]
                        ]
                    , a
                        [ href "#"
                        , onClick (SetTab NotificationDueItemsTab)
                        , menuEntryActive model NotificationDueItemsTab
                        , class S.sidebarLink
                        ]
                        [ i [ class "fa fa-history" ] []
                        , span
                            [ class "ml-3" ]
                            [ text texts.dueItems ]
                        ]
                    , a
                        [ href "#"
                        , onClick (SetTab NotificationQueriesTab)
                        , menuEntryActive model NotificationQueriesTab
                        , class S.sidebarLink
                        ]
                        [ i [ class "fa fa-history" ] []
                        , span
                            [ class "ml-3" ]
                            [ text texts.genericQueries ]
                        ]
                    ]
                ]
            , a
                [ href "#"
                , onClick (SetTab ChannelTab)
                , menuEntryActive model ChannelTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-bullhorn" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.channelSettings ]
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
            , a
                [ href "#"
                , onClick (SetTab OtpTab)
                , menuEntryActive model OtpTab
                , class S.sidebarLink
                ]
                [ i [ class "fa fa-key" ] []
                , span
                    [ class "ml-3" ]
                    [ text texts.otpMenu ]
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
                viewNotificationInfo texts settings model

            Just NotificationWebhookTab ->
                viewNotificationHooks texts settings model

            Just NotificationQueriesTab ->
                viewNotificationQueries texts settings model

            Just NotificationDueItemsTab ->
                viewNotificationDueItems texts settings model

            Just ImapSettingsTab ->
                viewImapSettings texts settings model

            Just ScanMailboxTab ->
                viewScanMailboxManage texts flags settings model

            Just UiSettingsTab ->
                viewUiSettings texts flags settings model

            Just OtpTab ->
                viewOtpSetup texts settings model

            Just ChannelTab ->
                viewChannels texts settings model

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


viewChannels : Texts -> UiSettings -> Model -> List (Html Msg)
viewChannels texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-bell" ] []
        , div [ class "ml-3" ]
            [ text texts.channels
            ]
        ]
    , Markdown.toHtml [ class "opacity-80  text-lg mb-3 markdown-preview" ] texts.channelInfoText
    , Html.map ChannelMsg
        (Comp.NotificationChannelManage.view texts.channelManage
            settings
            model.channelModel
        )
    ]


viewOtpSetup : Texts -> UiSettings -> Model -> List (Html Msg)
viewOtpSetup texts _ model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-key" ] []
        , div [ class "ml-3" ]
            [ text texts.otpMenu
            ]
        ]
    , Html.map OtpSetupMsg
        (Comp.OtpSetup.view
            texts.otpSetup
            model.otpSetupModel
        )
    ]


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


viewNotificationInfo : Texts -> UiSettings -> Model -> List (Html Msg)
viewNotificationInfo texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-bullhorn" ] []
        , div [ class "ml-3" ]
            [ text texts.notifications
            ]
        ]
    , Markdown.toHtml [ class "opacity-80 text-lg max-w-prose mb-3 markdown-preview" ] texts.notificationInfoText
    , div [ class "mt-2" ]
        [ ul [ class "list-none ml-8" ]
            [ li [ class "py-2" ]
                [ a
                    [ href "#"
                    , onClick (SetTab NotificationWebhookTab)
                    , class S.link
                    ]
                    [ i [ class "fa fa-bell" ] []
                    , span
                        [ class "ml-3" ]
                        [ text texts.webhooks ]
                    ]
                , div [ class "ml-3 text-sm opacity-50" ]
                    [ text texts.webhookInfoText
                    ]
                ]
            , li [ class "py-2" ]
                [ a
                    [ href "#"
                    , onClick (SetTab NotificationDueItemsTab)
                    , class S.link
                    ]
                    [ i [ class "fa fa-history" ] []
                    , span
                        [ class "ml-3" ]
                        [ text texts.dueItems ]
                    ]
                , div [ class "ml-3 text-sm opacity-50" ]
                    [ text texts.dueItemsInfoText
                    ]
                ]
            , li [ class "py-2" ]
                [ a
                    [ href "#"
                    , onClick (SetTab NotificationQueriesTab)
                    , class S.link
                    ]
                    [ Icons.periodicTasksIcon ""
                    , span
                        [ class "ml-3" ]
                        [ text texts.genericQueries ]
                    ]
                , div [ class "ml-3 text-sm opacity-50" ]
                    [ text texts.periodicQueryInfoText
                    ]
                ]
            ]
        ]
    ]


viewNotificationDueItems : Texts -> UiSettings -> Model -> List (Html Msg)
viewNotificationDueItems texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-history" ] []
        , div [ class "ml-3" ]
            [ text texts.dueItems
            ]
        ]
    , Markdown.toHtml [ class "opacity-80 text-lg mb-3 markdown-preview" ] texts.dueItemsInfoText
    , Html.map NotificationMsg
        (Comp.DueItemsTaskManage.view2 texts.notificationManage
            settings
            model.notificationModel
        )
    ]


viewNotificationQueries : Texts -> UiSettings -> Model -> List (Html Msg)
viewNotificationQueries texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-history" ] []
        , div [ class "ml-3" ]
            [ text texts.genericQueries
            ]
        ]
    , Markdown.toHtml [ class "opacity-80  text-lg mb-3 markdown-preview" ] texts.periodicQueryInfoText
    , Html.map PeriodicQueryMsg
        (Comp.PeriodicQueryTaskManage.view texts.periodicQueryTask
            settings
            model.periodicQueryModel
        )
    ]


viewNotificationHooks : Texts -> UiSettings -> Model -> List (Html Msg)
viewNotificationHooks texts settings model =
    [ h2
        [ class S.header1
        , class "inline-flex items-center"
        ]
        [ i [ class "fa fa-bell" ] []
        , div [ class "ml-3" ]
            [ text texts.webhooks
            ]
        ]
    , Markdown.toHtml [ class "opacity-80  text-lg mb-3 markdown-preview" ] texts.webhookInfoText
    , Html.map NotificationHookMsg
        (Comp.NotificationHookManage.view texts.notificationHookManage
            settings
            model.notificationHookModel
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
