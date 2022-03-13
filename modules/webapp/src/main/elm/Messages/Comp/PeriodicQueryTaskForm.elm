{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PeriodicQueryTaskForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.BookmarkDropdown
import Messages.Comp.CalEventInput
import Messages.Comp.ChannelForm
import Messages.Comp.ChannelRefInput
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , channelForm : Messages.Comp.ChannelForm.Texts
    , bookmarkDropdown : Messages.Comp.BookmarkDropdown.Texts
    , channelRef : Messages.Comp.ChannelRefInput.Texts
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
    , channelHeader : String
    , messageContentTitle : String
    , messageContentLabel : String
    , messageContentInfo : String
    , messageContentPlaceholder : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb tz
    , channelForm = Messages.Comp.ChannelForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , bookmarkDropdown = Messages.Comp.BookmarkDropdown.gb
    , channelRef = Messages.Comp.ChannelRefInput.gb
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
    , queryStringRequired = "A query string and/or bookmark must be supplied"
    , channelHeader = "Channels"
    , messageContentTitle = "Customize message"
    , messageContentLabel = "Beginning of message"
    , messageContentInfo = "Insert text that is prependend to the generated message."
    , messageContentPlaceholder = "Hello, this is Docspell informing you about new items …"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de tz
    , channelForm = Messages.Comp.ChannelForm.de
    , httpError = Messages.Comp.HttpError.de
    , bookmarkDropdown = Messages.Comp.BookmarkDropdown.de
    , channelRef = Messages.Comp.ChannelRefInput.de
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
    , queryStringRequired = "Eine Suchabfrage und/oder ein Bookmark muss angegeben werden."
    , channelHeader = "Kanäle"
    , messageContentTitle = "Nachricht anpassen"
    , messageContentLabel = "Anfang der Nachricht"
    , messageContentInfo = "Dieser Text wird an den Anfang der generierten Nachricht angefügt."
    , messageContentPlaceholder = "Hallo, hier ist Docspell mit den nächsten Themen …"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , calEventInput = Messages.Comp.CalEventInput.fr tz
    , channelForm = Messages.Comp.ChannelForm.fr
    , httpError = Messages.Comp.HttpError.fr
    , bookmarkDropdown = Messages.Comp.BookmarkDropdown.fr
    , channelRef = Messages.Comp.ChannelRefInput.fr
    , reallyDeleteTask = "Confirmer la suppresion de cette tâche ?"
    , startOnce = "Exécuter une seule fois"
    , startTaskNow = "Démarrer cette tâche maintenant"
    , deleteThisTask = "Supprimer cette tâche"
    , enableDisable = "Activer ou désactiver cette tâche"
    , summary = "Résumé"
    , summaryInfo = "Un nom, uniquement pour affichage"
    , schedule = "Programmation"
    , scheduleClickForHelp = "Cliquer pour l'aide"
    , scheduleInfo =
        "Spécifie la fréquence à laquelle cette tâche doit être lancée"
            ++ "Utiliser les jours de la semaine anglais en 3 lettres. Soit un valeur simple, "
            ++ "une liste (ex: 1,2,3), un interval (ex: 1..3) ou '*' (pour tous) "
            ++ "est autorisé pour chaque partie."
    , invalidCalEvent = "Evénement calendaire invalide"
    , queryLabel = "Requête"
    , channelRequired = "Un canal valide doit être spécifié"
    , queryStringRequired = "Un requête sous forme de chaine de caractères et/ou favoris sont requis"
    , channelHeader = "Canaux"
    , messageContentTitle = "Personnaliser le message"
    , messageContentLabel = "Début du message"
    , messageContentInfo = "Texte ajouté au message généré"
    , messageContentPlaceholder = "Bonjour, docspell vous informe de l'arrivée de nouveaux documents."
    }
