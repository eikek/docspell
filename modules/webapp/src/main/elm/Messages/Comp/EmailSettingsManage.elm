module Messages.Comp.EmailSettingsManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.EmailSettingsForm
import Messages.Comp.EmailSettingsTable
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , settingsForm : Messages.Comp.EmailSettingsForm.Texts
    , settingsTable : Messages.Comp.EmailSettingsTable.Texts
    , httpError : Http.Error -> String
    , newSettings : String
    , addNewSmtpSettings : String
    , reallyDeleteConnection : String
    , deleteThisEntry : String
    , fillRequiredFields : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , settingsForm = Messages.Comp.EmailSettingsForm.gb
    , settingsTable = Messages.Comp.EmailSettingsTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newSettings = "New Settings"
    , addNewSmtpSettings = "Add new SMTP settings"
    , reallyDeleteConnection = "Really delete these connection?"
    , deleteThisEntry = "Delete this connection"
    , fillRequiredFields = "Please fill required fields."
    }
