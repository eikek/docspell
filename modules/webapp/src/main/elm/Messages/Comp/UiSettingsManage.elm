module Messages.Comp.UiSettingsManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.UiSettingsForm


type alias Texts =
    { basics : Messages.Basics.Texts
    , uiSettingsForm : Messages.Comp.UiSettingsForm.Texts
    , saveSettings : String
    , settingsUnchanged : String
    , settingsSaved : String
    , unknownSaveError : String
    , httpError : Http.Error -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , uiSettingsForm = Messages.Comp.UiSettingsForm.gb
    , saveSettings = "Save settings"
    , settingsUnchanged = "Settings unchanged or invalid."
    , settingsSaved = "Settings saved."
    , unknownSaveError = "Unknown error while trying to save settings."
    , httpError = Messages.Comp.HttpError.gb
    }
