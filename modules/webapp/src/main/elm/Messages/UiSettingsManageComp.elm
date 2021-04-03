module Messages.UiSettingsManageComp exposing (..)

import Messages.Basics
import Messages.UiSettingsFormComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , uiSettingsForm : Messages.UiSettingsFormComp.Texts
    , saveSettings : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , uiSettingsForm = Messages.UiSettingsFormComp.gb
    , saveSettings = "Save settings"
    }
