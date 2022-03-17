{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Comp.DetailEdit
import Messages.Comp.HttpError
import Messages.Comp.ItemDetail.AddFilesForm
import Messages.Comp.ItemDetail.ConfirmModal
import Messages.Comp.ItemDetail.ItemInfoHeader
import Messages.Comp.ItemDetail.Notes
import Messages.Comp.ItemDetail.SingleAttachment
import Messages.Comp.ItemLinkForm
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
    , itemLinkForm : Messages.Comp.ItemLinkForm.Texts
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
    , undeleteThisItem : String
    , sentEmails : String
    , sendThisItemViaEmail : String
    , itemId : String
    , createdOn : String
    , lastUpdateOn : String
    , sendingMailNow : String
    , formatDateTime : Int -> String
    , mailSendSuccessful : String
    , showQrCode : String
    , close : String
    , selectItem : String
    , deselectItem : String
    , relatedItems : String
    }


gb : TimeZone -> Texts
gb tz =
    { addFilesForm = Messages.Comp.ItemDetail.AddFilesForm.gb
    , itemInfoHeader = Messages.Comp.ItemDetail.ItemInfoHeader.gb tz
    , singleAttachment = Messages.Comp.ItemDetail.SingleAttachment.gb tz
    , sentMails = Messages.Comp.SentMails.gb tz
    , notes = Messages.Comp.ItemDetail.Notes.gb
    , itemMail = Messages.Comp.ItemMail.gb
    , detailEdit = Messages.Comp.DetailEdit.gb
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.gb
    , itemLinkForm = Messages.Comp.ItemLinkForm.gb tz
    , httpError = Messages.Comp.HttpError.gb
    , key = "Key"
    , backToSearchResults = "Back to search results"
    , previousItem = "Previous item"
    , nextItem = "Next item"
    , sendMail = "Send Mail"
    , addMoreFiles = "Add more files to this item"
    , confirmItemMetadata = "Confirm metadata"
    , confirm = "Confirm"
    , unconfirmItemMetadata = "Un-confirm item metadata"
    , reprocessItem = "Reprocess this item"
    , deleteThisItem = "Delete this item"
    , undeleteThisItem = "Restore this item"
    , sentEmails = "Sent E-Mails"
    , sendThisItemViaEmail = "Send this item via E-Mail"
    , itemId = "Item ID"
    , createdOn = "Created on"
    , lastUpdateOn = "Last update on"
    , sendingMailNow = "Sending e-mail…"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English tz
    , mailSendSuccessful = "Mail sent."
    , showQrCode = "Show URL as QR code"
    , close = "Close"
    , selectItem = "Select this item"
    , deselectItem = "Deselect this item"
    , relatedItems = "Linked items"
    }


de : TimeZone -> Texts
de tz =
    { addFilesForm = Messages.Comp.ItemDetail.AddFilesForm.de
    , itemInfoHeader = Messages.Comp.ItemDetail.ItemInfoHeader.de tz
    , singleAttachment = Messages.Comp.ItemDetail.SingleAttachment.de tz
    , sentMails = Messages.Comp.SentMails.de tz
    , notes = Messages.Comp.ItemDetail.Notes.de
    , itemMail = Messages.Comp.ItemMail.de
    , detailEdit = Messages.Comp.DetailEdit.de
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.de
    , itemLinkForm = Messages.Comp.ItemLinkForm.de tz
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
    , undeleteThisItem = "Das Dokument wiederherstellen"
    , sentEmails = "Versendete E-Mails"
    , sendThisItemViaEmail = "Sende dieses Dokument via E-Mail"
    , itemId = "Dokument-ID"
    , createdOn = "Erstellt am"
    , lastUpdateOn = "Letzte Aktualisierung"
    , sendingMailNow = "E-Mail wird gesendet…"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German tz
    , mailSendSuccessful = "E-Mail wurde versendet."
    , showQrCode = "Link als QR code anzeigen"
    , close = "Schließen"
    , selectItem = "Zur Auswahl hinzufügen"
    , deselectItem = "Aus Auswahl entfernen"
    , relatedItems = "Verknüpfte Dokumente"
    }


fr : TimeZone -> Texts
fr tz =
    { addFilesForm = Messages.Comp.ItemDetail.AddFilesForm.fr
    , itemInfoHeader = Messages.Comp.ItemDetail.ItemInfoHeader.fr tz
    , singleAttachment = Messages.Comp.ItemDetail.SingleAttachment.fr tz
    , sentMails = Messages.Comp.SentMails.fr tz
    , notes = Messages.Comp.ItemDetail.Notes.fr
    , itemMail = Messages.Comp.ItemMail.fr
    , detailEdit = Messages.Comp.DetailEdit.fr
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.fr
    , itemLinkForm = Messages.Comp.ItemLinkForm.fr tz
    , httpError = Messages.Comp.HttpError.fr
    , key = "Clé"
    , backToSearchResults = "Retour aux résultat de recherche"
    , previousItem = "Document précédent"
    , nextItem = "Document suivant"
    , sendMail = "Envoyer par mail"
    , addMoreFiles = "Ajouter plus de fichier à ce document"
    , confirmItemMetadata = "Valider  les metadonnées"
    , confirm = "Valider"
    , unconfirmItemMetadata = "Invalider  les metadonnées"
    , reprocessItem = "Retraiter le document"
    , deleteThisItem = "Supprimer ce document"
    , undeleteThisItem = "Restorer  ce document"
    , sentEmails = "E-Mail envoyés"
    , sendThisItemViaEmail = "Envoyer  ce document par E-Mail"
    , itemId = "Item ID"
    , createdOn = "Créé le"
    , lastUpdateOn = "Dernière mise à jour le"
    , sendingMailNow = "e-mail en cours d'envoi…"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.French tz
    , mailSendSuccessful = "Mail envoyé."
    , showQrCode = "Afficher l'URL en  QR code"
    , close = "Fermer"
    , selectItem = "Sélectionner  ce document"
    , deselectItem = "Désélectionner  ce document"
    , relatedItems = "Documents associés"
    }
