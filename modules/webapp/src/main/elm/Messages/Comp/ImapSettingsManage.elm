module Messages.Comp.ImapSettingsManage exposing (..)

import Messages.Basics
import Messages.Comp.ImapSettingsForm
import Messages.Comp.ImapSettingsTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , imapForm : Messages.Comp.ImapSettingsForm.Texts
    , imapTable : Messages.Comp.ImapSettingsTable.Texts
    , addNewImapSettings : String
    , newSettings : String
    , reallyDeleteSettings : String
    , deleteThisEntry : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , imapForm = Messages.Comp.ImapSettingsForm.gb
    , imapTable = Messages.Comp.ImapSettingsTable.gb
    , addNewImapSettings = "Add new IMAP settings"
    , newSettings = "New Settings"
    , reallyDeleteSettings = "Really delete this mail-box connection?"
    , deleteThisEntry = "Delete this settings entry"
    }
