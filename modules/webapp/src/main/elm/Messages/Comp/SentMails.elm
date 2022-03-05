{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.SentMails exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { from : String
    , date : String
    , recipients : String
    , subject : String
    , sent : String
    , sender : String
    , formatDateTime : Int -> String
    }


gb : TimeZone -> Texts
gb tz =
    { from = "From"
    , date = "Date"
    , recipients = "Recipients"
    , subject = "Subject"
    , sent = "Sent"
    , sender = "Sender"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English tz
    }


de : TimeZone -> Texts
de tz =
    { from = "Von"
    , date = "Datum"
    , recipients = "Empfänger"
    , subject = "Betreff"
    , sent = "Gesendet"
    , sender = "Absender"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German tz
    }


fr : TimeZone -> Texts
fr tz =
    { from = "De"
    , date = "Date"
    , recipients = "Destinataires"
    , subject = "Sujet"
    , sent = "Envoyé"
    , sender = "Expéditeur"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.French tz
    }
