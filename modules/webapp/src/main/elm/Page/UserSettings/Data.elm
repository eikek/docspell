{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.UserSettings.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , init
    )

import Comp.ChangePasswordForm
import Comp.DueItemsTaskManage
import Comp.EmailSettingsManage
import Comp.ImapSettingsManage
import Comp.NotificationHookManage
import Comp.OtpSetup
import Comp.PeriodicQueryTaskManage
import Comp.ScanMailboxManage
import Comp.UiSettingsManage
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (StoredUiSettings, UiSettings)


type alias Model =
    { currentTab : Maybe Tab
    , changePassModel : Comp.ChangePasswordForm.Model
    , emailSettingsModel : Comp.EmailSettingsManage.Model
    , imapSettingsModel : Comp.ImapSettingsManage.Model
    , notificationModel : Comp.DueItemsTaskManage.Model
    , scanMailboxModel : Comp.ScanMailboxManage.Model
    , uiSettingsModel : Comp.UiSettingsManage.Model
    , otpSetupModel : Comp.OtpSetup.Model
    , notificationHookModel : Comp.NotificationHookManage.Model
    , periodicQueryModel : Comp.PeriodicQueryTaskManage.Model
    }


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    let
        ( um, uc ) =
            Comp.UiSettingsManage.init flags settings

        ( otpm, otpc ) =
            Comp.OtpSetup.init flags

        ( nhm, nhc ) =
            Comp.NotificationHookManage.init flags

        ( pqm, pqc ) =
            Comp.PeriodicQueryTaskManage.init flags
    in
    ( { currentTab = Just UiSettingsTab
      , changePassModel = Comp.ChangePasswordForm.emptyModel
      , emailSettingsModel = Comp.EmailSettingsManage.emptyModel
      , imapSettingsModel = Comp.ImapSettingsManage.emptyModel
      , notificationModel = Tuple.first (Comp.DueItemsTaskManage.init flags)
      , scanMailboxModel = Tuple.first (Comp.ScanMailboxManage.init flags)
      , uiSettingsModel = um
      , otpSetupModel = otpm
      , notificationHookModel = nhm
      , periodicQueryModel = pqm
      }
    , Cmd.batch
        [ Cmd.map UiSettingsMsg uc
        , Cmd.map OtpSetupMsg otpc
        , Cmd.map NotificationHookMsg nhc
        , Cmd.map PeriodicQueryMsg pqc
        ]
    )


type Tab
    = ChangePassTab
    | EmailSettingsTab
    | ImapSettingsTab
    | NotificationTab
    | NotificationWebhookTab
    | NotificationQueriesTab
    | NotificationDueItemsTab
    | ScanMailboxTab
    | UiSettingsTab
    | OtpTab


type Msg
    = SetTab Tab
    | ChangePassMsg Comp.ChangePasswordForm.Msg
    | EmailSettingsMsg Comp.EmailSettingsManage.Msg
    | NotificationMsg Comp.DueItemsTaskManage.Msg
    | ImapSettingsMsg Comp.ImapSettingsManage.Msg
    | ScanMailboxMsg Comp.ScanMailboxManage.Msg
    | UiSettingsMsg Comp.UiSettingsManage.Msg
    | OtpSetupMsg Comp.OtpSetup.Msg
    | NotificationHookMsg Comp.NotificationHookManage.Msg
    | PeriodicQueryMsg Comp.PeriodicQueryTaskManage.Msg
    | UpdateSettings
    | ReceiveBrowserSettings StoredUiSettings
