module Messages.Comp.ScanMailboxForm exposing (..)

import Messages.Basics
import Messages.Comp.CalEventInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
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
    , folderOwnerWarning : String
    , tagsInfo : String
    , documentLanguage : String
    , documentLanguageInfo : String
    , schedule : String
    , scheduleClickForHelp : String
    , scheduleInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb
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
    , connectionInfo = "The IMAP connection to use when sending notification mails."
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
    , folderOwnerWarning = """
You are **not a member** of this folder. Items created from mails in
this mailbox will be **hidden** from any search results. Use a folder
where you are a member of to make items visible. This message will
disappear then.
                      """
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
    }
