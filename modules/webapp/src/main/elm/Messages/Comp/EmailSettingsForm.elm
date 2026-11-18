{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.EmailSettingsForm exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Data.SSLType exposing (SSLType)
import Messages.Basics
import Messages.Data.SSLType


type alias Texts =
    { basics : Messages.Basics.Texts
    , sslTypeLabel : SSLType -> String
    , connectionPlaceholder : String
    , connectionNameInfo : String
    , smtpHost : String
    , smtpHostPlaceholder : String
    , smtpPort : String
    , smtpUser : String
    , smtpUserPlaceholder : String
    , smtpPassword : String
    , smtpPasswordPlaceholder : String
    , fromAddress : String
    , fromAddressPlaceholder : String
    , replyTo : String
    , replyToPlaceholder : String
    , ssl : String
    , ignoreCertCheck : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , sslTypeLabel = Messages.Data.SSLType.gb
    , connectionPlaceholder = "Connection name, e.g. 'gmail.com'"
    , connectionNameInfo = "The connection name must not contain whitespace or special characters."
    , smtpHost = "SMTP Host"
    , smtpHostPlaceholder = "SMTP host name, e.g. 'mail.gmail.com'"
    , smtpPort = "SMTP Port"
    , smtpUser = "SMTP User"
    , smtpUserPlaceholder = "SMTP Username, e.g. 'your.name@gmail.com'"
    , smtpPassword = "SMTP Password"
    , smtpPasswordPlaceholder = "Password"
    , fromAddress = "From Address"
    , fromAddressPlaceholder = "Sender E-Mail address"
    , replyTo = "Reply-To"
    , replyToPlaceholder = "Optional Reply-To E-Mail address"
    , ssl = "SSL"
    , ignoreCertCheck = "Ignore certificate check"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , sslTypeLabel = Messages.Data.SSLType.de
    , connectionPlaceholder = "Name der Verbindung, z.B. 'gmail.com'"
    , connectionNameInfo = "Der Name muss eine gültige ID sein, es dürfen keine Leer- oder Sonderzeichen verwendet werden."
    , smtpHost = "SMTP-Server"
    , smtpHostPlaceholder = "SMTP-Server, z.B. 'mail.gmail.com'"
    , smtpPort = "SMTP-Port"
    , smtpUser = "SMTP-Benutzer"
    , smtpUserPlaceholder = "SMTP-Benutzername, z.B. 'your.name@gmail.com'"
    , smtpPassword = "SMTP-Passwort"
    , smtpPasswordPlaceholder = "Passwort"
    , fromAddress = "Absenderadresse"
    , fromAddressPlaceholder = "E-Mail-Adresse des Absenders"
    , replyTo = "Antwort an"
    , replyToPlaceholder = "Optionale Antwortadresse"
    , ssl = "SSL"
    , ignoreCertCheck = "Zertifikatsprüfung ignorieren"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , sslTypeLabel = Messages.Data.SSLType.fr
    , connectionPlaceholder = "Nom de la connection ex: 'gmail.com'"
    , connectionNameInfo = "Le nom ne doit pas comprendre d'espace ou de caractères spéciaux."
    , smtpHost = "Hôte SMTP"
    , smtpHostPlaceholder = "SMTP hostname ex: 'mail.gmail.com'"
    , smtpPort = "Port SMTP"
    , smtpUser = "Identifiant SMTP"
    , smtpUserPlaceholder = "identifiant SMTP, ex: 'your.name@gmail.com'"
    , smtpPassword = "Mot de passe SMTP"
    , smtpPasswordPlaceholder = "Mot de passe"
    , fromAddress = "De"
    , fromAddressPlaceholder = "Email de l'expéditeur"
    , replyTo = "Répondre à"
    , replyToPlaceholder = "Adresse de réponse optionnelle"
    , ssl = "SSL"
    , ignoreCertCheck = "Ignorer la vérification des certificats"
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , sslTypeLabel = Messages.Data.SSLType.pt
    , connectionPlaceholder = "Nome da conexão, ex.: 'gmail.com'"
    , connectionNameInfo = "O nome da conexão não deve conter espaços em branco ou caracteres especiais."
    , smtpHost = "Host SMTP"
    , smtpHostPlaceholder = "Nome do host SMTP, ex.: 'mail.gmail.com'"
    , smtpPort = "Porta SMTP"
    , smtpUser = "Usuário SMTP"
    , smtpUserPlaceholder = "Nome de usuário SMTP, ex.: 'seu.nome@gmail.com'"
    , smtpPassword = "Senha SMTP"
    , smtpPasswordPlaceholder = "Senha"
    , fromAddress = "Endereço do remetente"
    , fromAddressPlaceholder = "Endereço de e-mail do remetente"
    , replyTo = "Responder a"
    , replyToPlaceholder = "Endereço de e-mail de resposta opcional"
    , ssl = "SSL"
    , ignoreCertCheck = "Ignorar verificação de certificado"
    }
