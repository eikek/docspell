{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.ImapSettingsForm exposing
    ( Texts
    , de
    , gb
    )

import Data.SSLType exposing (SSLType)
import Messages.Basics
import Messages.Data.SSLType


type alias Texts =
    { basics : Messages.Basics.Texts
    , sslTypeLabel : SSLType -> String
    , connectionNamePlaceholder : String
    , connectionNameInfo : String
    , imapHost : String
    , imapHostPlaceholder : String
    , imapPort : String
    , imapUser : String
    , imapUserPlaceholder : String
    , imapPassword : String
    , imapPasswordPlaceholder : String
    , ssl : String
    , ignoreCertCheck : String
    , enableOAuth2 : String
    , oauth2Info : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , sslTypeLabel = Messages.Data.SSLType.gb
    , connectionNamePlaceholder = "Connection name, e.g. 'gmail.com'"
    , connectionNameInfo = "The connection name must not contain whitespace or special characters."
    , imapHost = "IMAP Host"
    , imapHostPlaceholder = "IMAP host name, e.g. 'mail.gmail.com'"
    , imapPort = "IMAP Port"
    , imapUser = "IMAP User"
    , imapUserPlaceholder = "IMAP Username, e.g. 'your.name@gmail.com'"
    , imapPassword = "IMAP Password"
    , imapPasswordPlaceholder = "Password"
    , ssl = "SSL"
    , ignoreCertCheck = "Ignore certificate check"
    , enableOAuth2 = "Enable OAuth2 authentication"
    , oauth2Info = "Enabling this, allows to connect via XOAuth using the password as access token."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , sslTypeLabel = Messages.Data.SSLType.de
    , connectionNamePlaceholder = "Name der Verbindung, z.B. 'gmail.com'"
    , connectionNameInfo = "Der Name muss eine gültige ID sein, es dürfen keine Leer- oder Sonderzeichen verwendet werden."
    , imapHost = "IMAP-Server"
    , imapHostPlaceholder = "IMAP-Servername, z.B. 'mail.gmail.com'"
    , imapPort = "IMAP-Port"
    , imapUser = "IMAP-Benutzer"
    , imapUserPlaceholder = "IMAP-Benutzername, z.B. 'your.name@gmail.com'"
    , imapPassword = "IMAP-Passwort"
    , imapPasswordPlaceholder = "Passwort"
    , ssl = "SSL"
    , ignoreCertCheck = "Zertifikatprüfung ignorieren"
    , enableOAuth2 = "Aktiviere OAuth2-Authentifizierung"
    , oauth2Info = "Wenn dies aktiviert ist, wird via XOAuth authentifiziert wobei das Passwort als Access-Token verwendet wird."
    }
