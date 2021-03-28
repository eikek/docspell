module Messages.SourceManageComp exposing (..)

import Messages.Basics
import Messages.SourceFormComp
import Messages.SourceTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , sourceTable : Messages.SourceTableComp.Texts
    , sourceForm : Messages.SourceFormComp.Texts
    , addSourceUrl : String
    , newSource : String
    , publicUploads : String
    , sourceInfoText : String
    , itemsCreatedInfo : Int -> String
    , publicUploadPage : String
    , copyToClipboard : String
    , openInNewTab : String
    , publicUploadUrl : String
    , reallyDeleteSource : String
    , createNewSource : String
    , deleteThisSource : String
    , errorGeneratingQR : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , sourceTable = Messages.SourceTableComp.gb
    , sourceForm = Messages.SourceFormComp.gb
    , addSourceUrl = "Add a source url"
    , newSource = "New source"
    , publicUploads = "Public Uploads"
    , sourceInfoText =
        "This source defines URLs that can be used by anyone to send files to "
            ++ "you. There is a web page that you can share or the API url can be used "
            ++ "with other clients."
    , itemsCreatedInfo =
        \n ->
            "There have been "
                ++ String.fromInt n
                ++ " items created through this source."
    , publicUploadPage = "Public Upload Page"
    , copyToClipboard = "Copy to clipboard"
    , openInNewTab = "Open in new tab/window"
    , publicUploadUrl = "Public API Upload URL"
    , reallyDeleteSource = "Really delete this source?"
    , createNewSource = "Create new source"
    , deleteThisSource = "Delete this source"
    , errorGeneratingQR = "Error generating QR Code"
    }
