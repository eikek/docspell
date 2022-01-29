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
import Data.AppEvent exposing (AppEvent(..))
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Page.UserSettings.Data exposing (..)


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , appEvent : AppEvent
    }


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none AppNothing


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
                    , appEvent = AppNothing
                    }

                ImapSettingsTab ->
                    let
                        ( em, c ) =
                            Comp.ImapSettingsManage.init flags
                    in
                    { model = { m | imapSettingsModel = em }
                    , cmd = Cmd.map ImapSettingsMsg c
                    , sub = Sub.none
                    , appEvent = AppNothing
                    }

                ChangePassTab ->
                    unit m

                NotificationTab ->
                    unit m

                NotificationWebhookTab ->
                    let
                        ( _, nc ) =
                            Comp.NotificationHookManage.init flags
                    in
                    { model = m
                    , cmd = Cmd.map NotificationHookMsg nc
                    , sub = Sub.none
                    , appEvent = AppNothing
                    }

                NotificationQueriesTab ->
                    let
                        initCmd =
                            Cmd.map NotificationMsg
                                (Tuple.second (Comp.DueItemsTaskManage.init flags))
                    in
                    UpdateResult m initCmd Sub.none AppNothing

                NotificationDueItemsTab ->
                    let
                        initCmd =
                            Cmd.map NotificationMsg
                                (Tuple.second (Comp.DueItemsTaskManage.init flags))
                    in
                    UpdateResult m initCmd Sub.none AppNothing

                ScanMailboxTab ->
                    let
                        initCmd =
                            Cmd.map ScanMailboxMsg
                                (Tuple.second (Comp.ScanMailboxManage.init flags))
                    in
                    UpdateResult m initCmd Sub.none AppNothing

                UiSettingsTab ->
                    let
                        ( um, uc ) =
                            Comp.UiSettingsManage.init flags
                    in
                    { model = { m | uiSettingsModel = um }
                    , cmd = Cmd.map UiSettingsMsg uc
                    , sub = Sub.none
                    , appEvent = AppNothing
                    }

                OtpTab ->
                    unit m

                ChannelTab ->
                    unit m

        ChangePassMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ChangePasswordForm.update flags m model.changePassModel
            in
            { model = { model | changePassModel = m2 }
            , cmd = Cmd.map ChangePassMsg c2
            , sub = Sub.none
            , appEvent = AppNothing
            }

        EmailSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EmailSettingsManage.update flags m model.emailSettingsModel
            in
            { model = { model | emailSettingsModel = m2 }
            , cmd = Cmd.map EmailSettingsMsg c2
            , sub = Sub.none
            , appEvent = AppNothing
            }

        ImapSettingsMsg m ->
            let
                ( m2, c2 ) =
                    Comp.ImapSettingsManage.update flags m model.imapSettingsModel
            in
            { model = { model | imapSettingsModel = m2 }
            , cmd = Cmd.map ImapSettingsMsg c2
            , sub = Sub.none
            , appEvent = AppNothing
            }

        NotificationMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.DueItemsTaskManage.update flags lm model.notificationModel
            in
            { model = { model | notificationModel = m2 }
            , cmd = Cmd.map NotificationMsg c2
            , sub = Sub.none
            , appEvent = AppNothing
            }

        ScanMailboxMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.ScanMailboxManage.update flags lm model.scanMailboxModel
            in
            { model = { model | scanMailboxModel = m2 }
            , cmd = Cmd.map ScanMailboxMsg c2
            , sub = Sub.none
            , appEvent = AppNothing
            }

        UiSettingsMsg lm ->
            let
                res =
                    Comp.UiSettingsManage.update flags settings lm model.uiSettingsModel
            in
            { model = { model | uiSettingsModel = res.model }
            , cmd = Cmd.map UiSettingsMsg res.cmd
            , sub = Sub.map UiSettingsMsg res.sub
            , appEvent = res.appEvent
            }

        OtpSetupMsg lm ->
            let
                ( otpm, otpc ) =
                    Comp.OtpSetup.update flags lm model.otpSetupModel
            in
            { model = { model | otpSetupModel = otpm }
            , cmd = Cmd.map OtpSetupMsg otpc
            , sub = Sub.none
            , appEvent = AppNothing
            }

        NotificationHookMsg lm ->
            let
                ( hm, hc ) =
                    Comp.NotificationHookManage.update flags lm model.notificationHookModel
            in
            { model = { model | notificationHookModel = hm }
            , cmd = Cmd.map NotificationHookMsg hc
            , sub = Sub.none
            , appEvent = AppNothing
            }

        ChannelMsg lm ->
            let
                ( cm, cc ) =
                    Comp.NotificationChannelManage.update flags lm model.channelModel
            in
            { model = { model | channelModel = cm }
            , cmd = Cmd.map ChannelMsg cc
            , sub = Sub.none
            , appEvent = AppNothing
            }

        PeriodicQueryMsg lm ->
            let
                ( pqm, pqc, pqs ) =
                    Comp.PeriodicQueryTaskManage.update flags lm model.periodicQueryModel
            in
            { model = { model | periodicQueryModel = pqm }
            , cmd = Cmd.map PeriodicQueryMsg pqc
            , sub = Sub.map PeriodicQueryMsg pqs
            , appEvent = AppNothing
            }
