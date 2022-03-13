{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.SingleAttachment exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Comp.AttachmentMeta
import Messages.Comp.ItemDetail.ConfirmModal


type alias Texts =
    { attachmentMeta : Messages.Comp.AttachmentMeta.Texts
    , confirmModal : Messages.Comp.ItemDetail.ConfirmModal.Texts
    , noName : String
    , openFileInNewTab : String
    , downloadFile : String
    , renameFile : String
    , downloadOriginalArchiveFile : String
    , originalFile : String
    , renderPdfByBrowser : String
    , viewExtractedData : String
    , reprocessFile : String
    , deleteThisFile : String
    , selectModeTitle : String
    , exitSelectMode : String
    , deleteAttachments : String
    , showQrCode : String
    }


gb : TimeZone -> Texts
gb tz =
    { attachmentMeta = Messages.Comp.AttachmentMeta.gb tz
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.gb
    , noName = "No name"
    , openFileInNewTab = "Open file in new tab"
    , downloadFile = "Download file"
    , renameFile = "Rename file"
    , downloadOriginalArchiveFile = "Download original archive"
    , originalFile = "Original file"
    , renderPdfByBrowser = "Render pdf by browser"
    , viewExtractedData = "View extracted data"
    , reprocessFile = "Re-process this file"
    , deleteThisFile = "Delete this file"
    , selectModeTitle = "Select Mode"
    , exitSelectMode = "Exit Select Mode"
    , deleteAttachments = "Delete attachments"
    , showQrCode = "Show URL as QR code"
    }


de : TimeZone -> Texts
de tz =
    { attachmentMeta = Messages.Comp.AttachmentMeta.de tz
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.de
    , noName = "Kein Name"
    , openFileInNewTab = "Anhang im neuen Tab öffnen"
    , downloadFile = "Anhang herunterladen"
    , renameFile = "Anhang umbenennen"
    , downloadOriginalArchiveFile = "Originale Archivdatei herunterladen"
    , originalFile = "Originaldatei"
    , renderPdfByBrowser = "PDF nativ durch Browser rendern"
    , viewExtractedData = "Extrahierte Daten ansehen"
    , reprocessFile = "Anhang nochmal verarbeiten"
    , deleteThisFile = "Anhang löschen"
    , selectModeTitle = "Auswahlmodus"
    , exitSelectMode = "Auswahlmodus beenden"
    , deleteAttachments = "Anhänge löschen"
    , showQrCode = "Link als QR Code anzeigen"
    }


fr : TimeZone -> Texts
fr tz =
    { attachmentMeta = Messages.Comp.AttachmentMeta.fr tz
    , confirmModal = Messages.Comp.ItemDetail.ConfirmModal.fr
    , noName = "Sans nom"
    , openFileInNewTab = "Ouvrir le fichier dans un nouvel onglet"
    , downloadFile = "Télécharger le fichier"
    , renameFile = "Renommer le fichier"
    , downloadOriginalArchiveFile = "Télécharger l'archive original"
    , originalFile = "Fichier original"
    , renderPdfByBrowser = "Rendu des pdf pas le navigateur"
    , viewExtractedData = "Voir les données extraites"
    , reprocessFile = "Retraiter ce fichier"
    , deleteThisFile = "Supprimer ce fichier"
    , selectModeTitle = "Mode sélection"
    , exitSelectMode = "Quitter le mode sélection"
    , deleteAttachments = "Supprimer les pièces-jointes"
    , showQrCode = "Afficher l'URL en QR code"
    }
