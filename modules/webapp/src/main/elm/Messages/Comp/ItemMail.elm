{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemMail exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , selectConnection : String
    , sendVia : String
    , recipients : String
    , ccRecipients : String
    , bccRecipients : String
    , subject : String
    , body : String
    , includeAllAttachments : String
    , connectionMissing : String
    , sendLabel : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , selectConnection = "Select connection..."
    , sendVia = "Send via"
    , recipients = "Recipient(s)"
    , ccRecipients = "CC recipient(s)"
    , bccRecipients = "BCC recipient(s)..."
    , subject = "Subject"
    , body = "Body"
    , includeAllAttachments = "Include all item attachments"
    , connectionMissing = "No E-Mail connections configured. Goto user settings to add one."
    , sendLabel = "Send"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , selectConnection = "Verbindung wählen..."
    , sendVia = "Senden via"
    , recipients = "Empfänger"
    , ccRecipients = "CC"
    , bccRecipients = "BCC"
    , subject = "Betreff"
    , body = "Inhalt"
    , includeAllAttachments = "Alle Anhänge mit einfügen"
    , connectionMissing = "Keine E-Mail-Verbindung definiert. Gehe zu den Benutzereinstellungen und füge eine hinzu."
    , sendLabel = "Senden"
    }
