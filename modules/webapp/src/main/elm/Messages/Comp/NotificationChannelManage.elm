{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationChannelManage exposing (Texts, de, gb)

import Http
import Messages.Basics
import Messages.Comp.ChannelForm
import Messages.Comp.HttpError
import Messages.Comp.NotificationChannelTable
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.Comp.ChannelForm.Texts
    , notificationTable : Messages.Comp.NotificationChannelTable.Texts
    , httpError : Http.Error -> String
    , channelType : Messages.Data.ChannelType.Texts
    , newChannel : String
    , channelCreated : String
    , channelUpdated : String
    , channelDeleted : String
    , formInvalid : String
    , integrate : String
    , intoDocspell : String
    , postRequestInfo : String
    , notifyEmailInfo : String
    , addChannel : String
    , updateChannel : String
    , deleteThisChannel : String
    , reallyDeleteChannel : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.Comp.ChannelForm.gb
    , notificationTable = Messages.Comp.NotificationChannelTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , channelType = Messages.Data.ChannelType.gb
    , newChannel = "New Channel"
    , channelCreated = "Channel created"
    , channelUpdated = "Channel updated"
    , channelDeleted = "Channel deleted"
    , formInvalid = "Please fill in all required fields"
    , integrate = "Integrate"
    , intoDocspell = "into Docspell"
    , postRequestInfo = "Docspell will send POST requests with JSON payload."
    , notifyEmailInfo = "Get notified via e-mail."
    , addChannel = "Add new channel"
    , updateChannel = "Update channel"
    , deleteThisChannel = "Kanal löschen"
    , reallyDeleteChannel = "Really delete this channel?"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , notificationForm = Messages.Comp.ChannelForm.de
    , notificationTable = Messages.Comp.NotificationChannelTable.de
    , httpError = Messages.Comp.HttpError.de
    , channelType = Messages.Data.ChannelType.de
    , newChannel = "Neuer Kanal"
    , channelCreated = "Kanal wurde angelegt."
    , channelUpdated = "Kanal wurde aktualisiert."
    , channelDeleted = "Kanal wurde entfernt."
    , formInvalid = "Bitte alle erforderlichen Felder ausfüllen"
    , integrate = "Integriere"
    , intoDocspell = "in Docspell"
    , postRequestInfo = "Docspell wird JSON POST requests senden."
    , notifyEmailInfo = "Werde per E-Mail benachrichtigt."
    , addChannel = "Neuen Kanal hinzufügen"
    , updateChannel = "Kanal aktualisieren"
    , deleteThisChannel = "Kanal löschen"
    , reallyDeleteChannel = "Den Kanal wirklich löschen?"
    }
