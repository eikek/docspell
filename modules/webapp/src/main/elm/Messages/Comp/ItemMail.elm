module Messages.Comp.ItemMail exposing (Texts, gb)

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
