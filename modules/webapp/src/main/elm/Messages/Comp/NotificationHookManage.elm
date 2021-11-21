{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationHookManage exposing
    ( Texts
    , de
    , gb
    )

import Html exposing (Html, text)
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
    , matrix : String
    , gotify : String
    , email : String
    , httpRequest : String
    , hookCreated : String
    , hookUpdated : String
    , hookStarted : String
    , hookDeleted : String
    , deleteThisHook : String
    , reallyDeleteHook : String
    , formInvalid : String
    , invalidJsonFilter : String -> String
    , integrate : String
    , intoDocspell : String
    , postRequestInfo : String
    , updateWebhook : String
    , addWebhook : String
    , notifyEmailInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.Comp.NotificationHookForm.gb
    , notificationTable = Messages.Comp.NotificationHookTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , channelType = Messages.Data.ChannelType.gb
    , newHook = "New Webhook"
    , matrix = "Matrix"
    , gotify = "Gotify"
    , email = "E-Mail"
    , httpRequest = "HTTP Request"
    , hookCreated = "Webhook created"
    , hookUpdated = "Webhook updated"
    , hookStarted = "Webhook executed"
    , hookDeleted = "Webhook deleted"
    , deleteThisHook = "Delete this webhook"
    , reallyDeleteHook = "Really delete this webhook?"
    , formInvalid = "Please fill in all required fields"
    , invalidJsonFilter = \m -> "Event filter invalid: " ++ m
    , integrate = "Integrate"
    , intoDocspell = "into Docspell"
    , postRequestInfo = "Docspell will send POST requests with JSON payload."
    , updateWebhook = "Update webhook"
    , addWebhook = "Add new webhook"
    , notifyEmailInfo = "Get notified via e-mail."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , notificationForm = Messages.Comp.NotificationHookForm.de
    , notificationTable = Messages.Comp.NotificationHookTable.de
    , httpError = Messages.Comp.HttpError.de
    , channelType = Messages.Data.ChannelType.de
    , newHook = "Neuer Webhook"
    , matrix = "Matrix"
    , gotify = "Gotify"
    , email = "E-Mail"
    , httpRequest = "HTTP Request"
    , hookCreated = "Webhook erstellt"
    , hookUpdated = "Webhook aktualisiert"
    , hookStarted = "Webhook ausgeführt"
    , hookDeleted = "Webhook gelöscht"
    , deleteThisHook = "Diesen Webhook löschen"
    , reallyDeleteHook = "Den webhook wirklich löschen?"
    , formInvalid = "Bitte alle erforderlichen Felder ausfüllen"
    , invalidJsonFilter = \m -> "Ereignisfilter ist falsch: " ++ m
    , integrate = "Integriere"
    , intoDocspell = "in Docspell"
    , postRequestInfo = "Docspell wird JSON POST requests senden."
    , updateWebhook = "Webhook aktualisieren"
    , addWebhook = "Neuen Webhook hinzufügen"
    , notifyEmailInfo = "Werde per E-Mail benachrichtigt."
    }
