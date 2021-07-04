{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.UiSettingsManage exposing
    ( Texts
    , de
    , gb
    )

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


de : Texts
de =
    { basics = Messages.Basics.de
    , uiSettingsForm = Messages.Comp.UiSettingsForm.de
    , saveSettings = "Einstellungen speichern"
    , settingsUnchanged = "Einstellungen nicht verändert oder ungültig."
    , settingsSaved = "Einstellungen gespeichert"
    , unknownSaveError = "Unbekannter Fehler beim Speichern der Einstellungen."
    , httpError = Messages.Comp.HttpError.de
    }
