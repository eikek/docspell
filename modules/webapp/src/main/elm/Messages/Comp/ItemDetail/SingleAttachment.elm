module Messages.Comp.ItemDetail.SingleAttachment exposing (Texts, gb)

import Messages.Comp.AttachmentMeta


type alias Texts =
    { attachmentMeta : Messages.Comp.AttachmentMeta.Texts
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
    }


gb : Texts
gb =
    { attachmentMeta = Messages.Comp.AttachmentMeta.gb
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
    }
