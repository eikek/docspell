{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ShareManage exposing
    ( Texts
    , de
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ShareForm
import Messages.Comp.ShareMail
import Messages.Comp.ShareTable
import Messages.Comp.ShareView


type alias Texts =
    { basics : Messages.Basics.Texts
    , shareTable : Messages.Comp.ShareTable.Texts
    , shareForm : Messages.Comp.ShareForm.Texts
    , shareView : Messages.Comp.ShareView.Texts
    , shareMail : Messages.Comp.ShareMail.Texts
    , httpError : Http.Error -> String
    , newShare : String
    , copyToClipboard : String
    , openInNewTab : String
    , publicUrl : String
    , reallyDeleteShare : String
    , createNewShare : String
    , deleteThisShare : String
    , errorGeneratingQR : String
    , correctFormErrors : String
    , noName : String
    , shareInformation : String
    , sendViaMail : String
    , notOwnerInfo : String
    , showOwningSharesOnly : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , shareTable = Messages.Comp.ShareTable.gb tz
    , shareForm = Messages.Comp.ShareForm.gb
    , shareView = Messages.Comp.ShareView.gb tz
    , shareMail = Messages.Comp.ShareMail.gb
    , newShare = "New share"
    , copyToClipboard = "Copy to clipboard"
    , openInNewTab = "Open in new tab/window"
    , publicUrl = "Public URL"
    , reallyDeleteShare = "Really delete this share?"
    , createNewShare = "Create new share"
    , deleteThisShare = "Delete this share"
    , errorGeneratingQR = "Error generating QR Code"
    , correctFormErrors = "Please correct the errors in the form."
    , noName = "No Name"
    , shareInformation = "Share Information"
    , sendViaMail = "Send via E-Mail"
    , notOwnerInfo = "Only the user who created this share can edit its properties."
    , showOwningSharesOnly = "Show my shares only"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , shareTable = Messages.Comp.ShareTable.de tz
    , shareForm = Messages.Comp.ShareForm.de
    , shareView = Messages.Comp.ShareView.de tz
    , httpError = Messages.Comp.HttpError.de
    , shareMail = Messages.Comp.ShareMail.de
    , newShare = "Neue Freigabe"
    , copyToClipboard = "In die Zwischenablage kopieren"
    , openInNewTab = "Im neuen Tab/Fenster öffnen"
    , publicUrl = "Öffentliche URL"
    , reallyDeleteShare = "Diese Freigabe wirklich entfernen?"
    , createNewShare = "Neue Freigabe erstellen"
    , deleteThisShare = "Freigabe löschen"
    , errorGeneratingQR = "Fehler beim Generieren des QR-Code"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    , noName = "Ohne Name"
    , shareInformation = "Informationen zur Freigabe"
    , sendViaMail = "Per E-Mail versenden"
    , notOwnerInfo = "Nur der Benutzer, der diese Freigabe erstellt hat, kann diese auch ändern."
    , showOwningSharesOnly = "Nur meine Freigaben anzeigen"
    }
