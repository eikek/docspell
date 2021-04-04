module Messages.EmailSettingsManageComp exposing (..)

import Messages.Basics
import Messages.EmailSettingsFormComp
import Messages.EmailSettingsTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , settingsForm : Messages.EmailSettingsFormComp.Texts
    , settingsTable : Messages.EmailSettingsTableComp.Texts
    , newSettings : String
    , addNewSmtpSettings : String
    , reallyDeleteConnection : String
    , deleteThisEntry : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , settingsForm = Messages.EmailSettingsFormComp.gb
    , settingsTable = Messages.EmailSettingsTableComp.gb
    , newSettings = "New Settings"
    , addNewSmtpSettings = "Add new SMTP settings"
    , reallyDeleteConnection = "Really delete these connection?"
    , deleteThisEntry = "Delete this connection"
    }
