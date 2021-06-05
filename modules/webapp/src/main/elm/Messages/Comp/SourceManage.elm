module Messages.Comp.SourceManage exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.SourceForm
import Messages.Comp.SourceTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , sourceTable : Messages.Comp.SourceTable.Texts
    , sourceForm : Messages.Comp.SourceForm.Texts
    , httpError : Http.Error -> String
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
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , sourceTable = Messages.Comp.SourceTable.gb
    , sourceForm = Messages.Comp.SourceForm.gb
    , httpError = Messages.Comp.HttpError.gb
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
    , correctFormErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , sourceTable = Messages.Comp.SourceTable.de
    , sourceForm = Messages.Comp.SourceForm.de
    , httpError = Messages.Comp.HttpError.de
    , addSourceUrl = "Quell-URL hinzufügen"
    , newSource = "Neue Quelle"
    , publicUploads = "Öffentlicher Upload"
    , sourceInfoText =
        "Diese Quelle definiert eine zuällige URL, die von jedem genutzt werden kann, um Dateien ins "
            ++ "Kollektiv zu senden. Es gibt eine Webseite, die Du teilen kannst, oder die API URL "
            ++ "kann mit anderen Programmen, wie der Android App, verwendet werden."
    , itemsCreatedInfo =
        \n ->
            "Es wurden "
                ++ String.fromInt n
                ++ " dokumente durch diese Quelle erzeugt."
    , publicUploadPage = "Öffentliche Upload Webseite"
    , copyToClipboard = "In die Zwischenablage kopieren"
    , openInNewTab = "Im neuen Tab/Fenster öffnen"
    , publicUploadUrl = "Öffentliche API Upload URL"
    , reallyDeleteSource = "Diese Quelle wirklich entfernen?"
    , createNewSource = "Neue Quelle erstellen"
    , deleteThisSource = "Quelle löschen"
    , errorGeneratingQR = "Fehler beim Generieren des QR Code"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }
