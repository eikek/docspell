module Messages.Comp.EmailSettingsManage exposing
    ( Texts
    , de
    , gb
    )

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
    , newSettings = "New connection"
    , addNewSmtpSettings = "Add new SMTP settings"
    , reallyDeleteConnection = "Really delete these connection?"
    , deleteThisEntry = "Delete this connection"
    , fillRequiredFields = "Please fill required fields."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , settingsForm = Messages.Comp.EmailSettingsForm.de
    , settingsTable = Messages.Comp.EmailSettingsTable.de
    , httpError = Messages.Comp.HttpError.de
    , newSettings = "Neue Verbindung"
    , addNewSmtpSettings = "Neue SMTP-Einstellungen hinzufügen"
    , reallyDeleteConnection = "Diese Verbindung wirklich löschen?"
    , deleteThisEntry = "Verbindung löschen"
    , fillRequiredFields = "Bitte die erforderlichen Felder ausfüllen."
    }
