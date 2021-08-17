{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.SingleAttachment exposing
    ( Texts
    , de
    , gb
    )

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


gb : Texts
gb =
    { attachmentMeta = Messages.Comp.AttachmentMeta.gb
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


de : Texts
de =
    { attachmentMeta = Messages.Comp.AttachmentMeta.de
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
