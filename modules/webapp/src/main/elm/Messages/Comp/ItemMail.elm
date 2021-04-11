module Messages.Comp.ItemMail exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , selectConnection : String
    , sendVia : String
    , recipients : String
    , ccRecipients : String
    , bccRecipients : String
    , subject : String
    , body : String
    , includeAllAttachments : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , selectConnection = "Select connection..."
    , sendVia = "Send via"
    , recipients = "Recipient(s)"
    , ccRecipients = "CC recipient(s)"
    , bccRecipients = "BCC recipient(s)..."
    , subject = "Subject"
    , body = "Body"
    , includeAllAttachments = "Include all item attachments"
    }
