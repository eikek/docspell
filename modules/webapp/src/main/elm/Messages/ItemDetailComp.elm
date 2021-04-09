module Messages.ItemDetailComp exposing (..)

import Messages.DetailEditComp
import Messages.ItemDetail.AddFilesForm
import Messages.ItemInfoHeaderComp
import Messages.ItemMailComp
import Messages.NotesComp
import Messages.SentMailsComp
import Messages.SingleAttachmentComp


type alias Texts =
    { addFilesForm : Messages.ItemDetail.AddFilesForm.Texts
    , itemInfoHeader : Messages.ItemInfoHeaderComp.Texts
    , singleAttachment : Messages.SingleAttachmentComp.Texts
    , sentMails : Messages.SentMailsComp.Texts
    , notes : Messages.NotesComp.Texts
    , itemMail : Messages.ItemMailComp.Texts
    , detailEdit : Messages.DetailEditComp.Texts
    , key : String
    , backToSearchResults : String
    , previousItem : String
    , nextItem : String
    , sendMail : String
    , addMoreFiles : String
    , confirmItemMetadata : String
    , confirm : String
    , unconfirmItemMetadata : String
    , reprocessItem : String
    , deleteThisItem : String
    , sentEmails : String
    , sendThisItemViaEmail : String
    , itemId : String
    , createdOn : String
    , lastUpdateOn : String
    , sendingMailNow : String
    }


gb : Texts
gb =
    { addFilesForm = Messages.ItemDetail.AddFilesForm.gb
    , itemInfoHeader = Messages.ItemInfoHeaderComp.gb
    , singleAttachment = Messages.SingleAttachmentComp.gb
    , sentMails = Messages.SentMailsComp.gb
    , notes = Messages.NotesComp.gb
    , itemMail = Messages.ItemMailComp.gb
    , detailEdit = Messages.DetailEditComp.gb
    , key = "Key"
    , backToSearchResults = "Back to search results"
    , previousItem = "Previous item."
    , nextItem = "Next item."
    , sendMail = "Send Mail"
    , addMoreFiles = "Add more files to this item"
    , confirmItemMetadata = "Confirm item metadata"
    , confirm = "Confirm"
    , unconfirmItemMetadata = "Un-confirm item metadata"
    , reprocessItem = "Reprocess this item"
    , deleteThisItem = "Delete this item"
    , sentEmails = "Sent E-Mails"
    , sendThisItemViaEmail = "Send this item via E-Mail"
    , itemId = "Item ID"
    , createdOn = "Created on"
    , lastUpdateOn = "Last update on"
    , sendingMailNow = "Sending e-mail…"
    }
