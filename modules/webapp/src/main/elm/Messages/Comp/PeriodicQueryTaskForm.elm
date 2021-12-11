{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PeriodicQueryTaskForm exposing
    ( Texts
    , de
    , gb
    )

import Data.ChannelType exposing (ChannelType)
import Http
import Messages.Basics
import Messages.Comp.CalEventInput
import Messages.Comp.ChannelForm
import Messages.Comp.HttpError
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , channelForm : Messages.Comp.ChannelForm.Texts
    , httpError : Http.Error -> String
    , reallyDeleteTask : String
    , startOnce : String
    , startTaskNow : String
    , deleteThisTask : String
    , enableDisable : String
    , summary : String
    , summaryInfo : String
    , schedule : String
    , scheduleClickForHelp : String
    , scheduleInfo : String
    , queryLabel : String
    , invalidCalEvent : String
    , channelRequired : String
    , queryStringRequired : String
    , channelHeader : ChannelType -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb
    , channelForm = Messages.Comp.ChannelForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , reallyDeleteTask = "Really delete this notification task?"
    , startOnce = "Start Once"
    , startTaskNow = "Start this task now"
    , deleteThisTask = "Delete this task"
    , enableDisable = "Enable or disable this task."
    , summary = "Summary"
    , summaryInfo = "Some human readable name, only for displaying"
    , schedule = "Schedule"
    , scheduleClickForHelp = "Click here for help"
    , scheduleInfo =
        "Specify how often and when this task should run. "
            ++ "Use English 3-letter weekdays. Either a single value, "
            ++ "a list (ex. 1,2,3), a range (ex. 1..3) or a '*' (meaning all) "
            ++ "is allowed for each part."
    , invalidCalEvent = "The calendar event is not valid."
    , queryLabel = "Query"
    , channelRequired = "A valid channel must be given."
    , queryStringRequired = "A query string must be supplied"
    , channelHeader = \ct -> "Connection details for " ++ Messages.Data.ChannelType.gb ct
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de
    , channelForm = Messages.Comp.ChannelForm.de
    , httpError = Messages.Comp.HttpError.de
    , reallyDeleteTask = "Diesen Benachrichtigungsauftrag wirklich löschen?"
    , startOnce = "Jetzt starten"
    , startTaskNow = "Starte den Auftrag sofort"
    , deleteThisTask = "Den Auftrag löschen"
    , enableDisable = "Auftrag aktivieren oder deaktivieren"
    , summary = "Kurzbeschreibung"
    , summaryInfo = "Eine kurze lesbare Zusammenfassung, nur für die Anzeige"
    , schedule = "Zeitplan"
    , scheduleClickForHelp = "Klicke für Hilfe"
    , scheduleInfo =
        "Gib an, wie oft und wann der Auftrag laufen soll. "
            ++ "Verwende englische 3-Buchstaben Wochentage. Entweder ein einzelner Wert, "
            ++ "eine Liste (wie `1,2,3`), eine Bereich (wie `1..3`) oder ein '*' (für alle) "
            ++ "ist mögich für jeden Teil."
    , invalidCalEvent = "Das Kalenderereignis ist nicht gültig."
    , queryLabel = "Abfrage"
    , channelRequired = "Ein Versandkanal muss angegeben werden."
    , queryStringRequired = "Eine Suchabfrage muss angegeben werden."
    , channelHeader = \ct -> "Details für " ++ Messages.Data.ChannelType.de ct
    }
