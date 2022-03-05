{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.SourceManage exposing
    ( Texts
    , de
    , gb
    , fr
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
            ++ "Kollektiv zu senden. Es gibt eine Webseite die Du teilen kannst oder eine API-URL, "
            ++ "die mit anderen Programmen wie der Android App, verwendet werden kann."
    , itemsCreatedInfo =
        \n ->
            "Es wurden "
                ++ String.fromInt n
                ++ " Dokumente durch diese Quelle erzeugt."
    , publicUploadPage = "Öffentliche Upload-Webseite"
    , copyToClipboard = "In die Zwischenablage kopieren"
    , openInNewTab = "Im neuen Tab/Fenster öffnen"
    , publicUploadUrl = "Öffentliche API-Upload-URL"
    , reallyDeleteSource = "Diese Quelle wirklich entfernen?"
    , createNewSource = "Neue Quelle erstellen"
    , deleteThisSource = "Quelle löschen"
    , errorGeneratingQR = "Fehler beim Generieren des QR-Code"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , sourceTable = Messages.Comp.SourceTable.fr
    , sourceForm = Messages.Comp.SourceForm.fr
    , httpError = Messages.Comp.HttpError.fr
    , addSourceUrl = "Ajouter une url source"
    , newSource = "Nouvelle source"
    , publicUploads = "Envois publiques"
    , sourceInfoText =
        "Cette source défini les URL vers les lequelles n'importe qui peut vous envoyer"
            ++ "des fichiers. Il y a une page web pouvant être partagée ou l'url de l'API"
            ++ "peut être utilisée avec d'autres clients."
    , itemsCreatedInfo =
        \n ->
                ""
                ++ String.fromInt n
                ++ " documents créés via cette source."
    , publicUploadPage = "Page des envois publiques"
    , copyToClipboard = "Copier dans le presse-papier"
    , openInNewTab = "Ouvrir dans un nouvel onglet/fenêtre"
    , publicUploadUrl = "URL pour l'API publique d'envoi"
    , reallyDeleteSource = "Confirmer la suppression de cette source ?"
    , createNewSource = "Créer une nouvelle source"
    , deleteThisSource = "Supprimer cette source"
    , errorGeneratingQR = "Erreur lors de la génération du  QR Code"
    , correctFormErrors = "Veuillez corriger les erreurs du formulaire."
    }