module Messages.Comp.EmailSettingsForm exposing (..)

import Data.SSLType exposing (SSLType)
import Messages.Data.SSLType


type alias Texts =
    { sslTypeLabel : SSLType -> String
    , name : String
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
    { sslTypeLabel = Messages.Data.SSLType.gb
    , name = "Name"
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
    , replyToPlaceholder = "Optional reply-to E-Mail address"
    , ssl = "SSL"
    , ignoreCertCheck = "Ignore certificate check"
    }
