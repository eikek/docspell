{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ScanMailboxForm exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.CalEventInput
import Messages.Comp.HttpError
import Messages.Comp.TagDropdown


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , httpError : Http.Error -> String
    , tagDropdown : Messages.Comp.TagDropdown.Texts
    , reallyDeleteTask : String
    , startOnce : String
    , startNow : String
    , deleteThisTask : String
    , generalTab : String
    , processingTab : String
    , additionalFilterTab : String
    , postProcessingTab : String
    , metadataTab : String
    , scheduleTab : String
    , processingTabInfo : String
    , additionalFilterTabInfo : String
    , postProcessingTabInfo : String
    , metadataTabInfo : String
    , scheduleTabInfo : String
    , selectConnection : String
    , enableDisable : String
    , mailbox : String
    , summary : String
    , summaryInfo : String
    , connectionInfo : String
    , folders : String
    , foldersInfo : String
    , receivedHoursInfo : String
    , receivedHoursLabel : String
    , fileFilter : String
    , fileFilterInfo : String
    , subjectFilter : String
    , subjectFilterInfo : String
    , postProcessingLabel : String
    , postProcessingInfo : String
    , targetFolder : String
    , targetFolderInfo : String
    , deleteMailLabel : String
    , deleteMailInfo : String
    , itemDirection : String
    , automatic : String
    , itemDirectionInfo : String
    , itemFolder : String
    , itemFolderInfo : String
    , tagsInfo : String
    , documentLanguage : String
    , documentLanguageInfo : String
    , schedule : String
    , scheduleClickForHelp : String
    , scheduleInfo : String
    , connectionMissing : String
    , noProcessingFolders : String
    , invalidCalEvent : String
    , attachmentsOnlyLabel : String
    , attachmentsOnlyInfo : String
    , save : String
    , saveNewTitle : String
    , updateTitle : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb tz
    , httpError = Messages.Comp.HttpError.gb
    , tagDropdown = Messages.Comp.TagDropdown.gb
    , reallyDeleteTask = "Really delete this scan mailbox task?"
    , startOnce = "Start Once"
    , startNow = "Start this task now"
    , deleteThisTask = "Delete this task"
    , generalTab = "General"
    , processingTab = "Processing"
    , additionalFilterTab = "Additional Filter"
    , postProcessingTab = "Post Processing"
    , metadataTab = "Metadata"
    , scheduleTab = "Schedule"
    , processingTabInfo = "These settings define which mails are fetched from the mail server."
    , additionalFilterTabInfo = "These filters are applied to mails that have been fetched from the mailbox to select those that should be imported."
    , postProcessingTabInfo = "This defines what happens to mails that have been downloaded."
    , metadataTabInfo = "Define metadata that should be attached to all items created by this task."
    , scheduleTabInfo = "Define when mails should be imported."
    , selectConnection = "Select connection..."
    , enableDisable = "Enable or disable this task."
    , mailbox = "Mailbox"
    , summary = "Summary"
    , summaryInfo = "Some human readable name, only for displaying"
    , connectionInfo = "The IMAP connection to use for fetching mails."
    , folders = "Folders"
    , foldersInfo = "The folders to look for mails."
    , receivedHoursInfo = "Select mails newer than `now - receivedHours`"
    , receivedHoursLabel = "Received Since Hours"
    , fileFilter = "File Filter"
    , fileFilterInfo =
        "Specify a file glob to filter attachments. For example, to only extract pdf files: "
            ++ "`*.pdf`. If you want to include the mail body, allow html files or "
            ++ "`mail.html`. Globs can be combined via OR, like this: "
            ++ "`*.pdf|mail.html`. No file filter defaults to "
            ++ "`*` that includes all"
    , subjectFilter = "Subject Filter"
    , subjectFilterInfo =
        "Specify a file glob to filter mails by subject. For example: "
            ++ "`*Scanned Document*`. No file filter defaults to `*` that includes all."
    , postProcessingLabel = "Apply post-processing to all fetched mails."
    , postProcessingInfo =
        "When mails are fetched but not imported due to the 'Additional Filters', this flag can "
            ++ "control whether they should be moved to a target folder or deleted (whatever is "
            ++ "defined here) nevertheless. If unchecked only imported mails "
            ++ "are post-processed, others stay where they are."
    , targetFolder = "Target folder"
    , targetFolderInfo = "Move mails into this folder."
    , deleteMailLabel = "Delete imported mails"
    , deleteMailInfo =
        "Whether to delete all mails fetched by docspell. This only applies if "
            ++ "*target folder* is not set."
    , itemDirection = "Item direction"
    , automatic = "Automatic"
    , itemDirectionInfo =
        "Sets the direction for an item. If you know all mails are incoming or "
            ++ "outgoing, you can set it here. Otherwise it will be guessed from looking "
            ++ "at sender and receiver."
    , itemFolder = "Item Folder"
    , itemFolderInfo = "Put all items from this mailbox into the selected folder"
    , tagsInfo = "Choose tags that should be applied to items."
    , documentLanguage = "Language"
    , documentLanguageInfo =
        "Used for text extraction and text analysis. The "
            ++ "collective's default language is used, if not specified here."
    , schedule = "Schedule"
    , scheduleClickForHelp = "Click here for help"
    , scheduleInfo =
        "Specify how often and when this task should run. "
            ++ "Use English 3-letter weekdays. Either a single value, "
            ++ "a list (ex. 1,2,3), a range (ex. 1..3) or a '*' (meaning all) "
            ++ "is allowed for each part."
    , connectionMissing = "No E-Mail connections configured. Goto E-Mail Settings to add one."
    , noProcessingFolders = "No processing folders given."
    , invalidCalEvent = "The calendar event is not valid."
    , attachmentsOnlyLabel = "Only import e-mail attachments"
    , attachmentsOnlyInfo = "Discards the e-mail body and only imports the attachments."
    , save = "Save"
    , saveNewTitle = "Save a new task"
    , updateTitle = "Update the task"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de tz
    , httpError = Messages.Comp.HttpError.de
    , tagDropdown = Messages.Comp.TagDropdown.de
    , reallyDeleteTask = "Den Auftrag wirklich löschen?"
    , startOnce = "Jetzt starten"
    , startNow = "Den Auftrag sofort starten"
    , deleteThisTask = "Den Auftrag löschen"
    , generalTab = "Allgemein"
    , processingTab = "E-Mails abholen"
    , additionalFilterTab = "Zusätzliche Filter"
    , postProcessingTab = "Nachverarbeitung"
    , metadataTab = "Metadaten"
    , scheduleTab = "Zeitplan"
    , processingTabInfo = "Diese Einstellungen legen fest, welche E-Mails aus dem Postfach heruntergeladen werden."
    , additionalFilterTabInfo = "Diese Filter werden auf die bereits heruntergeladenen E-Mails angewendet und können nochmals E-Mails von der Verarbeitung ausschließen."
    , postProcessingTabInfo = "Hier wird definiert was mit den E-Mails passiert, die heruntergeladen wurden."
    , metadataTabInfo = "Welche Metadaten sollen den Dokumenten hinzugefügt werden."
    , scheduleTabInfo = "Wann und wie oft sollen die E-Mails abgerufen werden."
    , selectConnection = "Verbindung wählen…"
    , enableDisable = "Den Auftrag aktivieren oder deaktivieren"
    , mailbox = "Postfach"
    , summary = "Kurzbeschreibung"
    , summaryInfo = "Eine kurze, lesbare Zusammenfassung, nur für die Anzeige"
    , connectionInfo = "Die IMAP-Verbindung, die zum Abholen der E-Mails verwendet werden soll."
    , folders = "Postfachordner"
    , foldersInfo = "In diesem Ordner nach E-Mails suchen."
    , receivedHoursInfo = "E-Mails suchen, die neuer sind als `heute - empfangenSeit`"
    , receivedHoursLabel = "Empfangen seit (Stunden)"
    , fileFilter = "Dateifilter"
    , fileFilterInfo =
        "Verwende eine Glob zum Filtern von Anhängen. Zum Beispiel, um nur PDF-Anhänge aus den E-Mails zu holen: "
            ++ "`*.pdf`. Wenn auch der E-Mail-Inhalt verwendet werden soll, erlaube alle HTML-Dateien oder "
            ++ "`mail.html`. Globs können kombiniert werden mit ODER, wie z.B.: "
            ++ "`*.pdf|mail.html`. Wird kein Glob angegeben, ist es `*`, es werden alle Dateien verwendet."
    , subjectFilter = "Betrefffilter"
    , subjectFilterInfo =
        "Verwende einen Glob, um E-Mails anhand des Betreffs zu filtern. Zum Beispiel: "
            ++ "`*Scanned Document*`. Kein Filter bedeutet `*`, was jeden Betreff zulässt."
    , postProcessingLabel = "Wende die Nachverarbeitung auf alle heruntergeladenen E-Mails an."
    , postProcessingInfo = """
Heruntergeladene E-Mails, die aber durch die Filter nicht importiert wurden, können durch diese Option von der gesamten Nachverarbeitung ein- oder ausgeschlossen werden. Aktiviert: Die Nachbearbeitung wird bei allen E-Mails durchgeführt. Deaktiviert: Die Nachbearbeitung wird nur bei importierten E-Mails druchgeführt.
"""
    , targetFolder = "Zielordner"
    , targetFolderInfo = "E-Mails nach der Verarbeitung in diesen Ordner verschieben."
    , deleteMailLabel = "Importierte E-Mails löschen"
    , deleteMailInfo =
        "Importierte E-Mails aus dem Postfach löschen. E-Mails werden nur gelöscht falls *kein* Zielordner angegeben ist."
    , itemDirection = "Richtung"
    , automatic = "Automatisch"
    , itemDirectionInfo = """
Setzt die Senderichtung. Falls sie für alle E-Mails schon feststeht,
kann hier ein Wert für alle festgelegt werden. Bei 'Automatisch' wird auf den Sender und Empfänger geschaut, um eine Richtung zu erraten."""
    , itemFolder = "Ordner"
    , itemFolderInfo = "Alle Dokumente aus diesem Auftrag in den Ordner verschieben"
    , tagsInfo = "Wähle Tags, die den Dokumenten zugordnet werden"
    , documentLanguage = "Sprache"
    , documentLanguageInfo =
        "Wird für Texterkennung und -analyse verwendet. Die Standardsprache des Kollektivs "
            ++ "wird verwendet, falls hier nicht angegeben."
    , schedule = "Zeitplan"
    , scheduleClickForHelp = "Klicke für Hilfe"
    , scheduleInfo =
        "Gib an, wie oft und wann der Auftrag laufen soll. "
            ++ "Verwende englische 3-Buchstaben Wochentage. Entweder ein einzelner Wert, "
            ++ "eine Liste (wie `1,2,3`), eine Bereich (wie `1..3`) oder ein '*' (für alle) "
            ++ "ist mögich für jeden Teil."
    , connectionMissing = "Keine E-Mail-Verbindung definiert. Gehe zu den E-Mail-Einstellungen und füge eine hinzu."
    , noProcessingFolders = "Keine Postfachordner ausgewählt."
    , invalidCalEvent = "Das Kalenderereignis ist ungültig."
    , attachmentsOnlyLabel = "Nur Anhänge importieren"
    , attachmentsOnlyInfo = "Verwirft den E-Mail Text und importiert nur die Anhänge."
    , save = "Speichern"
    , saveNewTitle = "Einen neuen Auftrag speichern"
    , updateTitle = "Den Auftrag aktualisieren"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , calEventInput = Messages.Comp.CalEventInput.fr tz
    , httpError = Messages.Comp.HttpError.fr
    , tagDropdown = Messages.Comp.TagDropdown.fr
    , reallyDeleteTask = "Confirmer la suppression de cette tâche ?"
    , startOnce = "Exécuter une seule fois"
    , startNow = "Exécuter cette tâche maintenant"
    , deleteThisTask = "Supprimer cette tâche"
    , generalTab = "Général"
    , processingTab = "En cours d'exécution"
    , additionalFilterTab = "Filtre additionnel"
    , postProcessingTab = "Traitement ad hoc"
    , metadataTab = "Metadonnées"
    , scheduleTab = "Programmation"
    , processingTabInfo = "Ces paramètres définissent quel mails sont récupérés sur la boite mail."
    , additionalFilterTabInfo = "Ces filtres sont aplliqués à tous les mails récupérés afin de trier ceux qui doivent être importés."
    , postProcessingTabInfo = "Ceci définit ce qui arrive aux mails qui sont importés"
    , metadataTabInfo = "Défini les métadonnées qui seront affectées à tous les documents créés par cette tâche."
    , scheduleTabInfo = "Defini quand les mails doivent être importés"
    , selectConnection = "Choisir une connexion..."
    , enableDisable = "Active ou désactive cette tâche."
    , mailbox = "Mailbox"
    , summary = "Résumé"
    , summaryInfo = "Un texte pour humain, uniquement pour affichage"
    , connectionInfo = "La connexion IMAP utilisée pour récupérer les mails"
    , folders = "Dossiers"
    , foldersInfo = "Le dossier où chercher les mails"
    , receivedHoursInfo = "Sélectionner les mails plus récent que `maintenant - HeureDepuisRéception`"
    , receivedHoursLabel = "Heures depuis réception"
    , fileFilter = "Filtre de fichier"
    , fileFilterInfo =
        "Entrer un filtre 'glob' pour les pièces-jointes. Par example, pour extraire uniquement les pdf:"
            ++ " `*.pdf`. Pour inclure le corps du meassage, ajouter des fichiers html ou"
            ++ " `mail.html`. Les Globs peuvent être combinés avec OR:"
            ++ " `*.pdf|mail.html`. Aucun filtre par défaut correspond à `*`"
            ++ " qui revient à tout inclure"
    , subjectFilter = "Filtre de sujet"
    , subjectFilterInfo =
        "Entrer un filtre 'glob' s'appliquant au sujet. Par exemple: "
            ++ "`*Scanned Document*`. Aucun filtre correspond à `*` qui revient à tout inclure."
    , postProcessingLabel = "Appliquer le traitement add hoc tous les mails"
    , postProcessingInfo =
        "Quand des mails sont récupérés mais non importés du fait de 'filtres additionnels', cette option permet de "
            ++ "controler s'ils doivent être déplacés vers un dossier cible ou supprimés."
            ++ " Si non coché, seuls les mails importés bénéficient d'un traitement add hoc, les autres restent où ils sont."
    , targetFolder = "Dossier cible"
    , targetFolderInfo = "Déplacer les mails vers ce dossier"
    , deleteMailLabel = "Effacer les mails importés"
    , deleteMailInfo =
        "Supprimer ou non tous les mails importés dans docspell. Ceci ne s'applique que si le dossier cible n'est pas défini"
    , itemDirection = "Sens des documents"
    , automatic = "Automatique"
    , itemDirectionInfo =
        "Défini le sens pour un document. Si vous savez que tous les mails sont entrant ou sortant"
            ++ ", il est possible le fixer ici. Sinon ce sera déviné en regardant l'émetteur et le destinataire"
    , itemFolder = "Dossier documents"
    , itemFolderInfo = "Placer tous les documents d'une boite mail dans un dossier"
    , tagsInfo = "Choisir les tags à appliquer aux documents"
    , documentLanguage = "Langue"
    , documentLanguageInfo =
        "Utilisé pour l'extraction et l'analyse du texte. La langue"
            ++ "par défaut du groupe est utilisée, si non spécifié"
    , schedule = "Programmation"
    , scheduleClickForHelp = "Cliquer pour l'aide"
    , scheduleInfo =
        "Spécifie la fréquence à laquelle cette tâche doit être lancée"
            ++ "Utiliser les jours de la semaine anglais en 3 lettres. Soit un valeur simple, "
            ++ "une liste (ex: 1,2,3), un interval (ex: 1..3) ou '*' (pour tous) "
            ++ "est autorisé pour chaque partie."
    , connectionMissing = "Pas de connexion mail configurée. Aller dans parmètres mail pour en ajouter une."
    , noProcessingFolders = "Pas de dossier de traitement donné"
    , invalidCalEvent = "L'événement calendaire n'est pas valide"
    , attachmentsOnlyLabel = "Importer uniquement les pièces-jointes"
    , attachmentsOnlyInfo = "Ignore le corps des messages et importe uniquement les pièces-jointes"
    , save = "Enregistrer"
    , saveNewTitle = "Enregistrer une nouvelle tâche"
    , updateTitle = "Mettre à jour la tâche"
    }
