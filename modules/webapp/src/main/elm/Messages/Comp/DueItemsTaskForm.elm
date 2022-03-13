{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DueItemsTaskForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.CalEventInput
import Messages.Comp.ChannelForm
import Messages.Comp.ChannelRefInput
import Messages.Comp.HttpError
import Messages.Comp.TagDropdown
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , httpError : Http.Error -> String
    , channelForm : Messages.Comp.ChannelForm.Texts
    , tagDropdown : Messages.Comp.TagDropdown.Texts
    , channelType : Messages.Data.ChannelType.Texts
    , channelRef : Messages.Comp.ChannelRefInput.Texts
    , reallyDeleteTask : String
    , startOnce : String
    , startTaskNow : String
    , deleteThisTask : String
    , enableDisable : String
    , summary : String
    , summaryInfo : String
    , tagsInclude : String
    , tagsIncludeInfo : String
    , tagsExclude : String
    , tagsExcludeInfo : String
    , remindDaysInfo : String
    , remindDaysLabel : String
    , capOverdue : String
    , capOverdueInfo : String
    , schedule : String
    , scheduleClickForHelp : String
    , scheduleInfo : String
    , connectionMissing : String
    , invalidCalEvent : String
    , remindDaysRequired : String
    , recipientsRequired : String
    , queryLabel : String
    , channelRequired : String
    , channelHeader : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb tz
    , httpError = Messages.Comp.HttpError.gb
    , channelForm = Messages.Comp.ChannelForm.gb
    , tagDropdown = Messages.Comp.TagDropdown.gb
    , channelType = Messages.Data.ChannelType.gb
    , channelRef = Messages.Comp.ChannelRefInput.gb
    , reallyDeleteTask = "Really delete this notification task?"
    , startOnce = "Start Once"
    , startTaskNow = "Start this task now"
    , deleteThisTask = "Delete this task"
    , enableDisable = "Enable or disable this task."
    , summary = "Summary"
    , summaryInfo = "Some human readable name, only for displaying"
    , tagsInclude = "Tags Include (and)"
    , tagsIncludeInfo = "Items must have all the tags specified here."
    , tagsExclude = "Tags Exclude (or)"
    , tagsExcludeInfo = "Items must not have any tag specified here."
    , remindDaysLabel = "Remind Days"
    , remindDaysInfo = "Select items with a due date *lower than* `today+remindDays`"
    , capOverdue = "Cap overdue items"
    , capOverdueInfo = "If checked, only items with a due date *greater than* `today - remindDays` are considered."
    , schedule = "Schedule"
    , scheduleClickForHelp = "Click here for help"
    , scheduleInfo =
        "Specify how often and when this task should run. "
            ++ "Use English 3-letter weekdays. Either a single value, "
            ++ "a list (ex. 1,2,3), a range (ex. 1..3) or a '*' (meaning all) "
            ++ "is allowed for each part."
    , connectionMissing = "No E-Mail connections configured. Goto E-Mail Settings to add one."
    , invalidCalEvent = "The calendar event is not valid."
    , remindDaysRequired = "Remind-Days is required."
    , recipientsRequired = "At least one recipient is required."
    , queryLabel = "Query"
    , channelRequired = "A valid channel must be given."
    , channelHeader = "Channels"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de tz
    , httpError = Messages.Comp.HttpError.de
    , channelForm = Messages.Comp.ChannelForm.de
    , tagDropdown = Messages.Comp.TagDropdown.de
    , channelType = Messages.Data.ChannelType.de
    , channelRef = Messages.Comp.ChannelRefInput.de
    , reallyDeleteTask = "Diesen Benachrichtigungsauftrag wirklich löschen?"
    , startOnce = "Jetzt starten"
    , startTaskNow = "Starte den Auftrag sofort"
    , deleteThisTask = "Den Auftrag löschen"
    , enableDisable = "Auftrag aktivieren oder deaktivieren"
    , summary = "Kurzbeschreibung"
    , summaryInfo = "Eine kurze lesbare Zusammenfassung, nur für die Anzeige"
    , tagsInclude = "Tags verknüpft (&&)"
    , tagsIncludeInfo = "Dokumente müssen alle diese Tags haben."
    , tagsExclude = "Tags nicht verknüpft (||)"
    , tagsExcludeInfo = "Dokumente dürfen keine dieser Tags haben."
    , remindDaysLabel = "Fälligkeit in Tagen"
    , remindDaysInfo = "Wähle Dokumente, die in weniger als diesen Tagen fällig sind."
    , capOverdue = "Ignoriere überfällige Dokumente"
    , capOverdueInfo = "Wenn aktiviert, werden nur Dokumente gesucht, die vor weniger als 'Fällig in Tagen' fällig waren."
    , schedule = "Zeitplan"
    , scheduleClickForHelp = "Klicke für Hilfe"
    , scheduleInfo =
        "Gib an, wie oft und wann der Auftrag laufen soll. "
            ++ "Verwende englische 3-Buchstaben Wochentage. Entweder ein einzelner Wert, "
            ++ "eine Liste (wie `1,2,3`), eine Bereich (wie `1..3`) oder ein '*' (für alle) "
            ++ "ist mögich für jeden Teil."
    , connectionMissing = "Keine E-Mail-Verbindung definiert. Gehe zu den E-Mail-Einstellungen und füge eine hinzu."
    , invalidCalEvent = "Das Kalenderereignis ist nicht gültig."
    , remindDaysRequired = "'Fällig in Tagen' ist erforderlich."
    , recipientsRequired = "Mindestens ein Empfänger muss angegeben werden."
    , queryLabel = "Abfrage"
    , channelRequired = "Ein Versandkanal muss angegeben werden."
    , channelHeader = "Kanäle"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , calEventInput = Messages.Comp.CalEventInput.fr tz
    , httpError = Messages.Comp.HttpError.fr
    , channelForm = Messages.Comp.ChannelForm.fr
    , tagDropdown = Messages.Comp.TagDropdown.fr
    , channelType = Messages.Data.ChannelType.fr
    , channelRef = Messages.Comp.ChannelRefInput.fr
    , reallyDeleteTask = "Confirmer la suppression de cette tâche ?"
    , startOnce = "Lancer une une seule fois"
    , startTaskNow = "Démarrer cette tâche maintenant"
    , deleteThisTask = "Supprimer cette tâche"
    , enableDisable = "Activer ou désactiver cette tâche."
    , summary = "Résumé"
    , summaryInfo = "Lisible pour un humain, juste pour affichage"
    , tagsInclude = "Tags à inclure (and)"
    , tagsIncludeInfo = "Les documents doivent avoir tous les tags spécifiés ici."
    , tagsExclude = "Tags à exclure (or)"
    , tagsExcludeInfo = "Les documents ne doivent avoir aucun tag spécifié ici"
    , remindDaysLabel = "Jours de rappel"
    , remindDaysInfo = "Sélectionner les document avec un date d'échéance *plus petite que* `aujourd'hui+jours_restant`"
    , capOverdue = "Documents à échéance dépassée"
    , capOverdueInfo = "Si coché, seuls les documents avec une date d'échéance *supérieur à * `aujourd'hui - jours_restant` sont retenus."
    , schedule = "Programmation"
    , scheduleClickForHelp = "Cliquer ici pour l'aide"
    , scheduleInfo =
        "Spécifie quand et à quelle fréquence cette tâche doit se lancer."
            ++ "Utiliser les jours de la semaine à l'anglaise en 3 lettres. Soit une valeur simple, "
            ++ "une liste (ex: 1,2,3), un interval (ex: 1..3) ou  un '*' (pour ous) "
            ++ "est autorisé pour chaque partie."
    , connectionMissing = "Aucune connexion E-mail de configuré, aller dans Paramètres E-Mail pour en ajouter une."
    , invalidCalEvent = "L'événement du calendrier n'est pas valide"
    , remindDaysRequired = "Le nombre de jour de rappel est requis"
    , recipientsRequired = "Au moins un destinataire est requis."
    , queryLabel = "Requête"
    , channelRequired = "Un canal valide doit être entré."
    , channelHeader = "Canaux"
    }
