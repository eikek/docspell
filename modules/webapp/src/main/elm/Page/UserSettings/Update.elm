{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.UserSettings.Update exposing (UpdateResult, update)

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
import Data.UiSettings exposing (UiSettings)
import Page.UserSettings.Data exposing (..)


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , newSettings : Maybe UiSettings
    }


update : Flags -> UiSettings -> Msg -> Model -> UpdateResult
update flags settings msg model =
    case msg of
        SetTab t ->
            let
                m =
                    { model | currentTab = Just t }
            in
            case t of
                EmailSettingsTab ->
                    let
                        ( em, c ) =
                            Comp.EmailSettingsManage.init flags
                    in
                    { model = { m | emailSettingsModel = em }
                    , cmd = Cmd.map EmailSettingsMsg c
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

                ImapSettingsTab ->
                    let
                        ( em, c ) =
                            Comp.ImapSettingsManage.init flags
                    in
                    { model = { m | imapSettingsModel = em }
                    , cmd = Cmd.map ImapSettingsMsg c
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

                ChangePassTab ->
                    UpdateResult m Cmd.none Sub.none Nothing

                NotificationTab ->
                    { model = m
                    , cmd = Cmd.none
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

                NotificationWebhookTab ->
                    let
                        ( _, nc ) =
                            Comp.NotificationHookManage.init flags
                    in
                    { model = m
                    , cmd = Cmd.map NotificationHookMsg nc
                    , sub = Sub.none
                    , newSettings = Nothing
                    }

                NotificationQueriesTab ->
                    let
                        initCmd =
                            Cmd.map NotificationMsg
                                (Tuple.second (Comp.DueItemsTaskManage.init flags))
                    in
                    UpdateResult m initCmd Sub.none Nothing

                NotificationDueItemsTab ->
                    let
                        initCmd =
                            Cmd.map NotificationMsg
                                (Tuple.second (Comp.DueItemsTaskManage.init flags))
                    in
                    UpdateResult m initCmd Sub.none Nothing

                ScanMailboxTab ->
                    let
                        initCmd =
                            Cmd.map ScanMailboxMsg
                                (Tuple.second (Comp.ScanMailboxManage.init flags))
                    in
                    UpdateResult m initCmd Sub.none Nothing

                UiSettingsTab ->
                    UpdateResult m Cmd.none Sub.none Nothing

                OtpTab ->
                    UpdateResult m Cmd.none Sub.none Nothing

                ChannelTab ->
                    UpdateResult m Cmd.none Sub.none Nothing

        ChangePassMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ChangePasswordForm.update flags m model.changePassModel
            in
            { model = { model | changePassModel = m2 }
            , cmd = Cmd.map ChangePassMsg c2
            , sub = Sub.none
            , newSettings = Nothing
            }

        EmailSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EmailSettingsManage.update flags m model.emailSettingsModel
            in
            { model = { model | emailSettingsModel = m2 }
            , cmd = Cmd.map EmailSettingsMsg c2
            , sub = Sub.none
            , newSettings = Nothing
            }

        ImapSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ImapSettingsManage.update flags m model.imapSettingsModel
            in
            { model = { model | imapSettingsModel = m2 }
            , cmd = Cmd.map ImapSettingsMsg c2
            , sub = Sub.none
            , newSettings = Nothing
            }

        NotificationMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.DueItemsTaskManage.update flags lm model.notificationModel
            in
            { model = { model | notificationModel = m2 }
            , cmd = Cmd.map NotificationMsg c2
            , sub = Sub.none
            , newSettings = Nothing
            }

        ScanMailboxMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.ScanMailboxManage.update flags lm model.scanMailboxModel
            in
            { model = { model | scanMailboxModel = m2 }
            , cmd = Cmd.map ScanMailboxMsg c2
            , sub = Sub.none
            , newSettings = Nothing
            }

        UiSettingsMsg lm ->
            let
                res =
                    Comp.UiSettingsManage.update flags settings lm model.uiSettingsModel
            in
            { model = { model | uiSettingsModel = res.model }
            , cmd = Cmd.map UiSettingsMsg res.cmd
            , sub = Sub.map UiSettingsMsg res.sub
            , newSettings = res.newSettings
            }

        OtpSetupMsg lm ->
            let
                ( otpm, otpc ) =
                    Comp.OtpSetup.update flags lm model.otpSetupModel
            in
            { model = { model | otpSetupModel = otpm }
            , cmd = Cmd.map OtpSetupMsg otpc
            , sub = Sub.none
            , newSettings = Nothing
            }

        NotificationHookMsg lm ->
            let
                ( hm, hc ) =
                    Comp.NotificationHookManage.update flags lm model.notificationHookModel
            in
            { model = { model | notificationHookModel = hm }
            , cmd = Cmd.map NotificationHookMsg hc
            , sub = Sub.none
            , newSettings = Nothing
            }

        ChannelMsg lm ->
            let
                ( cm, cc ) =
                    Comp.NotificationChannelManage.update flags lm model.channelModel
            in
            { model = { model | channelModel = cm }
            , cmd = Cmd.map ChannelMsg cc
            , sub = Sub.none
            , newSettings = Nothing
            }

        UpdateSettings ->
            update flags
                settings
                (UiSettingsMsg Comp.UiSettingsManage.UpdateSettings)
                model

        ReceiveBrowserSettings sett ->
            let
                lm =
                    Comp.UiSettingsManage.ReceiveBrowserSettings sett
            in
            update flags settings (UiSettingsMsg lm) model

        PeriodicQueryMsg lm ->
            let
                ( pqm, pqc, pqs ) =
                    Comp.PeriodicQueryTaskManage.update flags lm model.periodicQueryModel
            in
            { model = { model | periodicQueryModel = pqm }
            , cmd = Cmd.map PeriodicQueryMsg pqc
            , sub = Sub.map PeriodicQueryMsg pqs
            , newSettings = Nothing
            }
