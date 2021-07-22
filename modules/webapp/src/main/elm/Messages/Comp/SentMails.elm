{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.SentMails exposing
    ( Texts
    , de
    , gb
    )

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


gb : Texts
gb =
    { from = "From"
    , date = "Date"
    , recipients = "Recipients"
    , subject = "Subject"
    , sent = "Sent"
    , sender = "Sender"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English
    }


de : Texts
de =
    { from = "Von"
    , date = "Datum"
    , recipients = "Empfänger"
    , subject = "Betreff"
    , sent = "Gesendet"
    , sender = "Absender"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German
    }
