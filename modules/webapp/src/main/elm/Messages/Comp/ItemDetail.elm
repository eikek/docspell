module Messages.Comp.ItemDetail exposing (Texts, gb)

import Messages.Comp.DetailEdit
import Messages.Comp.ItemDetail.AddFilesForm
import Messages.Comp.ItemDetail.ItemInfoHeader
import Messages.Comp.ItemDetail.Notes
import Messages.Comp.ItemDetail.SingleAttachment
import Messages.Comp.ItemMail
import Messages.Comp.SentMails
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { addFilesForm : Messages.Comp.ItemDetail.AddFilesForm.Texts
    , itemInfoHeader : Messages.Comp.ItemDetail.ItemInfoHeader.Texts
    , singleAttachment : Messages.Comp.ItemDetail.SingleAttachment.Texts
    , sentMails : Messages.Comp.SentMails.Texts
    , notes : Messages.Comp.ItemDetail.Notes.Texts
    , itemMail : Messages.Comp.ItemMail.Texts
    , detailEdit : Messages.Comp.DetailEdit.Texts
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
    , formatDateTime : Int -> String
    }


gb : Texts
gb =
    { addFilesForm = Messages.Comp.ItemDetail.AddFilesForm.gb
    , itemInfoHeader = Messages.Comp.ItemDetail.ItemInfoHeader.gb
    , singleAttachment = Messages.Comp.ItemDetail.SingleAttachment.gb
    , sentMails = Messages.Comp.SentMails.gb
    , notes = Messages.Comp.ItemDetail.Notes.gb
    , itemMail = Messages.Comp.ItemMail.gb
    , detailEdit = Messages.Comp.DetailEdit.gb
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
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English
    }
