{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
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
import Messages.Data.AccountScope


type alias Texts =
    { basics : Messages.Basics.Texts
    , uiSettingsForm : Messages.Comp.UiSettingsForm.Texts
    , accountScope : Messages.Data.AccountScope.Texts
    , saveSettings : String
    , settingsUnchanged : String
    , settingsSaved : String
    , unknownSaveError : String
    , httpError : Http.Error -> String
    , userHeader : String
    , userInfo : String
    , collectiveHeader : String
    , expandCollapse : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , uiSettingsForm = Messages.Comp.UiSettingsForm.gb
    , accountScope = Messages.Data.AccountScope.gb
    , saveSettings = "Save settings"
    , settingsUnchanged = "Settings unchanged or invalid."
    , settingsSaved = "Settings saved."
    , unknownSaveError = "Unknown error while trying to save settings."
    , httpError = Messages.Comp.HttpError.gb
    , userHeader = "Personal settings"
    , userInfo = "Your personal settings override those of the collective. On reset, settings are set back to those of the collective."
    , collectiveHeader = "Collective settings"
    , expandCollapse = "Expand/collapse all"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , uiSettingsForm = Messages.Comp.UiSettingsForm.de
    , accountScope = Messages.Data.AccountScope.de
    , saveSettings = "Einstellungen speichern"
    , settingsUnchanged = "Einstellungen nicht verändert oder ungültig."
    , settingsSaved = "Einstellungen gespeichert"
    , unknownSaveError = "Unbekannter Fehler beim Speichern der Einstellungen."
    , httpError = Messages.Comp.HttpError.de
    , userHeader = "Persönliche Einstellungen"
    , userInfo = "Die persönlichen Einstellungen überschreiben die des Kollektivs. Wenn Einstellungen zurückgesetzt werden, werden sie auf die Werte des Kollektivs gesetzt."
    , collectiveHeader = "Kollektiv Einstellungen"
    , expandCollapse = "Alle ein-/ausklappen"
    }
