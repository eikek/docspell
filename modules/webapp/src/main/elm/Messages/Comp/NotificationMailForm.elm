{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationMailForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , selectConnection : String
    , sendVia : String
    , sendViaInfo : String
    , recipients : String
    , recipientsInfo : String
    , recipientsRequired : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , selectConnection = "Select connection..."
    , sendVia = "Send via"
    , sendViaInfo = "The SMTP connection to use when sending notification mails."
    , recipients = "Recipient(s)"
    , recipientsInfo = "One or more mail addresses, confirm each by pressing 'Return'."
    , recipientsRequired = "At least one recipient is required."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , selectConnection = "Verbindung auswählen…"
    , sendVia = "Senden via"
    , sendViaInfo = "Die SMTP-Verbindung, die zum Senden der Benachrichtigungs-E-Mails verwendet werden soll."
    , recipients = "Empfänger"
    , recipientsInfo = "Eine oder mehrere E-Mail-Adressen, jede mit 'Eingabe' bestätigen."
    , recipientsRequired = "Mindestens ein Empfänger muss angegeben werden."
    }
