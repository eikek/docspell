module Messages.ImapSettingsManageComp exposing (..)

import Messages.Basics
import Messages.ImapSettingsFormComp
import Messages.ImapSettingsTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , imapForm : Messages.ImapSettingsFormComp.Texts
    , imapTable : Messages.ImapSettingsTableComp.Texts
    , addNewImapSettings : String
    , newSettings : String
    , reallyDeleteSettings : String
    , deleteThisEntry : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , imapForm = Messages.ImapSettingsFormComp.gb
    , imapTable = Messages.ImapSettingsTableComp.gb
    , addNewImapSettings = "Add new IMAP settings"
    , newSettings = "New Settings"
    , reallyDeleteSettings = "Really delete this mail-box connection?"
    , deleteThisEntry = "Delete this settings entry"
    }
