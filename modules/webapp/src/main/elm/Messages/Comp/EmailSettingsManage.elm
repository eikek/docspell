module Messages.Comp.EmailSettingsManage exposing (..)

import Messages.Basics
import Messages.Comp.EmailSettingsForm
import Messages.Comp.EmailSettingsTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , settingsForm : Messages.Comp.EmailSettingsForm.Texts
    , settingsTable : Messages.Comp.EmailSettingsTable.Texts
    , newSettings : String
    , addNewSmtpSettings : String
    , reallyDeleteConnection : String
    , deleteThisEntry : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , settingsForm = Messages.Comp.EmailSettingsForm.gb
    , settingsTable = Messages.Comp.EmailSettingsTable.gb
    , newSettings = "New Settings"
    , addNewSmtpSettings = "Add new SMTP settings"
    , reallyDeleteConnection = "Really delete these connection?"
    , deleteThisEntry = "Delete this connection"
    }
