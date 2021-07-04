{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.ItemDetail exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Comp.DetailEdit
import Messages.Comp.HttpError
import Messages.Comp.ItemDetail.AddFilesForm
import Messages.Comp.ItemDetail.ConfirmModal
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
    , confirmModal : Messages.Comp.ItemDetail.ConfirmModal.Texts
    , httpError : Http.Error -> String
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
    , mailSendSuccessful : String
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
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.gb
    , httpError = Messages.Comp.HttpError.gb
    , key = "Key"
    , backToSearchResults = "Back to search results"
    , previousItem = "Previous item"
    , nextItem = "Next item"
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
    , mailSendSuccessful = "Mail sent."
    }


de : Texts
de =
    { addFilesForm = Messages.Comp.ItemDetail.AddFilesForm.de
    , itemInfoHeader = Messages.Comp.ItemDetail.ItemInfoHeader.de
    , singleAttachment = Messages.Comp.ItemDetail.SingleAttachment.de
    , sentMails = Messages.Comp.SentMails.de
    , notes = Messages.Comp.ItemDetail.Notes.de
    , itemMail = Messages.Comp.ItemMail.de
    , detailEdit = Messages.Comp.DetailEdit.de
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.de
    , httpError = Messages.Comp.HttpError.de
    , key = "Taste"
    , backToSearchResults = "Zurück zur Suche"
    , previousItem = "Vorheriges Dokument"
    , nextItem = "Nächstes Dokument"
    , sendMail = "E-Mail senden"
    , addMoreFiles = "Diesem Dokument weitere Dateien anfügen"
    , confirmItemMetadata = "Metadaten bestätigen"
    , confirm = "Bestätige"
    , unconfirmItemMetadata = "Widerrufe Bestätigung"
    , reprocessItem = "Das Dokument erneut verarbeiten"
    , deleteThisItem = "Das Dokument löschen"
    , sentEmails = "Versendete E-Mails"
    , sendThisItemViaEmail = "Sende dieses Dokument via E-Mail"
    , itemId = "Dokument-ID"
    , createdOn = "Erstellt am"
    , lastUpdateOn = "Letzte Aktualisierung"
    , sendingMailNow = "E-Mail wird gesendet…"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German
    , mailSendSuccessful = "E-Mail wurde versendet."
    }
