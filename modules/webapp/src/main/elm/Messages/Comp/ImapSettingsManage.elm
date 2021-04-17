module Messages.Comp.ImapSettingsManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ImapSettingsForm
import Messages.Comp.ImapSettingsTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , imapForm : Messages.Comp.ImapSettingsForm.Texts
    , imapTable : Messages.Comp.ImapSettingsTable.Texts
    , httpError : Http.Error -> String
    , addNewImapSettings : String
    , newSettings : String
    , reallyDeleteSettings : String
    , deleteThisEntry : String
    , fillRequiredFields : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , imapForm = Messages.Comp.ImapSettingsForm.gb
    , imapTable = Messages.Comp.ImapSettingsTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , addNewImapSettings = "Add new IMAP settings"
    , newSettings = "New Settings"
    , reallyDeleteSettings = "Really delete this mail-box connection?"
    , deleteThisEntry = "Delete this settings entry"
    , fillRequiredFields = "Please fill required fields."
    }
