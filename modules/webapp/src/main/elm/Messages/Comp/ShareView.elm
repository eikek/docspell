{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ShareView exposing
    ( Texts
    , de
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , date : Int -> String
    , qrCodeError : String
    , expiredInfo : String
    , disabledInfo : String
    , noName : String
    , copyToClipboard : String
    , openInNewTab : String
    , publishUntil : String
    , passwordProtected : String
    , views : String
    , lastAccess : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , date = DF.formatDateLong Messages.UiLanguage.English tz
    , qrCodeError = "Error generating QR Code."
    , expiredInfo = "This share has expired."
    , disabledInfo = "This share is disabled."
    , noName = "No Name"
    , copyToClipboard = "Copy to clipboard"
    , openInNewTab = "Open in new tab/window"
    , publishUntil = "Published Until"
    , passwordProtected = "Password protected"
    , views = "Views"
    , lastAccess = "Last Access"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , date = DF.formatDateLong Messages.UiLanguage.German tz
    , qrCodeError = "Fehler beim Erzeugen des QR-Codes."
    , expiredInfo = "Diese Freigabe ist abgelaufen."
    , disabledInfo = "Diese Freigae ist nicht aktiv."
    , noName = "Ohne Name"
    , copyToClipboard = "In die Zwischenablage kopieren"
    , openInNewTab = "Im neuen Tab/Fenster öffnen"
    , publishUntil = "Publiziert bis"
    , passwordProtected = "Passwordgeschützt"
    , views = "Aufrufe"
    , lastAccess = "Letzter Zugriff"
    }
