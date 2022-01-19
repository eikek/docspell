{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHookManage exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.NotificationHookForm
import Messages.Comp.NotificationHookTable
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.Comp.NotificationHookForm.Texts
    , notificationTable : Messages.Comp.NotificationHookTable.Texts
    , httpError : Http.Error -> String
    , channelType : Messages.Data.ChannelType.Texts
    , newHook : String
    , httpRequest : String
    , hookCreated : String
    , hookUpdated : String
    , hookStarted : String
    , hookDeleted : String
    , deleteThisHook : String
    , reallyDeleteHook : String
    , formInvalid : String
    , invalidJsonFilter : String -> String
    , updateWebhook : String
    , addWebhook : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.Comp.NotificationHookForm.gb
    , notificationTable = Messages.Comp.NotificationHookTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , channelType = Messages.Data.ChannelType.gb
    , newHook = "New Webhook"
    , httpRequest = "HTTP Request"
    , hookCreated = "Webhook created"
    , hookUpdated = "Webhook updated"
    , hookStarted = "Webhook executed"
    , hookDeleted = "Webhook deleted"
    , deleteThisHook = "Delete this webhook"
    , reallyDeleteHook = "Really delete this webhook?"
    , formInvalid = "Please fill in all required fields"
    , invalidJsonFilter = \m -> "Event filter invalid: " ++ m
    , updateWebhook = "Update webhook"
    , addWebhook = "Add new webhook"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , notificationForm = Messages.Comp.NotificationHookForm.de
    , notificationTable = Messages.Comp.NotificationHookTable.de
    , httpError = Messages.Comp.HttpError.de
    , channelType = Messages.Data.ChannelType.de
    , newHook = "Neuer Webhook"
    , httpRequest = "HTTP Request"
    , hookCreated = "Webhook erstellt"
    , hookUpdated = "Webhook aktualisiert"
    , hookStarted = "Webhook ausgeführt"
    , hookDeleted = "Webhook gelöscht"
    , deleteThisHook = "Diesen Webhook löschen"
    , reallyDeleteHook = "Den webhook wirklich löschen?"
    , formInvalid = "Bitte alle erforderlichen Felder ausfüllen"
    , invalidJsonFilter = \m -> "Ereignisfilter ist falsch: " ++ m
    , updateWebhook = "Webhook aktualisieren"
    , addWebhook = "Neuen Webhook hinzufügen"
    }
