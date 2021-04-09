module Messages.Comp.UiSettingsManage exposing (..)

import Messages.Basics
import Messages.Comp.UiSettingsForm


type alias Texts =
    { basics : Messages.Basics.Texts
    , uiSettingsForm : Messages.Comp.UiSettingsForm.Texts
    , saveSettings : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , uiSettingsForm = Messages.Comp.UiSettingsForm.gb
    , saveSettings = "Save settings"
    }
