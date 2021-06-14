module Messages.Comp.ScanMailboxForm exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.CalEventInput
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , httpError : Http.Error -> String
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
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb
    , httpError = Messages.Comp.HttpError.gb
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
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de
    , httpError = Messages.Comp.HttpError.de
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
    , metadataTabInfo = "Gib an, welche Metadaten an Dokumente geknüpft werden sollen, die durch diesen Auftrag entstehen."
    , scheduleTabInfo = "Gib an, wann und wie oft die E-Mails abgeholt werden sollen."
    , selectConnection = "Verbindung wählen…"
    , enableDisable = "Aktiviere/Deaktiviere den Auftrag"
    , mailbox = "Postfach"
    , summary = "Kurzbeschreibung"
    , summaryInfo = "Eine kurze lesbare Zusammenfassung, nur für die Anzeige"
    , connectionInfo = "Die IMAP Verbindung, die zum Abholen der E-Mails verwendet werden soll."
    , folders = "Postfach Ordner"
    , foldersInfo = "In diesen Ordner nach E-Mails suchen."
    , receivedHoursInfo = "E-Mails suchen, die neuer sind als `heute - empfangenSeit`"
    , receivedHoursLabel = "Empfangen seit (Stunden)"
    , fileFilter = "Datei Filter"
    , fileFilterInfo =
        "Verwende eine Glob zum filtern von Anhängen. Zum Beispiel, um nur PDF Anhänge aus den Mails zu holen: "
            ++ "`*.pdf`. Wenn auch der E-Mail Inhalt verwendet werden soll, erlaube alle HTML Dateien oder "
            ++ "`mail.html`. Globs können kombiniert werden mit ODER, wie z.B.: "
            ++ "`*.pdf|mail.html`. Wird kein Glob angegeben, ist es `*`, es werden alle Dateien verwendet."
    , subjectFilter = "Betreff Filter"
    , subjectFilterInfo =
        "Verwende einen Glob, um E-Mails anhand des Betreffs zu filtern. Zum Beispiel: "
            ++ "`*Scanned Document*`. Kein Filter bedeutet `*`, was jeden Betreff zulässt."
    , postProcessingLabel = "Wende Nachverarbeitung auf alle heruntergeladenen E-Mails an."
    , postProcessingInfo = """
Heruntergeladene E-Mails, die aber durch die Filter nicht importiert wurden, können durch diese Option von der gesamten Nachverarbeitung ein- oder ausgeschlossen werden. Aktiviert: Die Nachbearbeitung wird bei allen Mails durchgeführt. Deaktiviert: Die Nachbearbeitung wird nur bei importierten Mails druchgeführt. 
"""
    , targetFolder = "Ziel-Ordner"
    , targetFolderInfo = "E-Mails nach der Verarbeitung in diesen Ordner verschieben."
    , deleteMailLabel = "Importierte E-Mails löschen"
    , deleteMailInfo =
        "Importierte E-Mails aus dem Postfach löschen. E-Mails werden nur gelöscht falls *kein* Zielordner angegeben ist."
    , itemDirection = "Richtung"
    , automatic = "Automatisch"
    , itemDirectionInfo = """
Setzt die Senderichtung des Dokuments. Falls sie für all diese Mails schon fest
steht, kann hier ein Wert für alle festgelegt werden. Bei 'Automatisch' wird auf den Sender und Empfänger geschaut, um eine Richtung zu erraten."""
    , itemFolder = "Dokumentordner"
    , itemFolderInfo = "Alle Dokumente aus diesem Auftrag in den Ordner verschieben"
    , tagsInfo = "Wähle Tags, die den Dokumenten zugordnet werden"
    , documentLanguage = "Sprache"
    , documentLanguageInfo =
        "Wird für Text-Extraktion und -Analyse verwendet. Die Standard-Sprache des Kollektivs "
            ++ "wird verwendet, falls hier nicht angegeben."
    , schedule = "Zeitplan"
    , scheduleClickForHelp = "Klicke für Hilfe"
    , scheduleInfo =
        "Gib an, wie oft und wann der Auftrag laufen soll. "
            ++ "Verwende Englische 3-Buchstaben Wochentage. Entweder ein einzelner Wert, "
            ++ "eine Liste (wie `1,2,3`), eine Bereich (wie `1..3`) oder ein '*' (für alle) "
            ++ "ist mögich für jeden Teil."
    , connectionMissing = "Keine E-Mail Verbindung definiert. Gehe zu den E-Mail Einstellungen und füge eine hinzu."
    , noProcessingFolders = "Keine Postfach-Ordner ausgewählt."
    , invalidCalEvent = "Das Kalender-Ereignis ist ungültig."
    }
