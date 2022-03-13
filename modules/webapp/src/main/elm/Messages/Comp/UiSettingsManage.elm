{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.UiSettingsManage exposing
    ( Texts
    , de
    , fr
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
    , collectiveInfo : String
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
    , userInfo = "Your personal settings override those of the collective. On reset, settings are taken from the collective settings."
    , collectiveHeader = "Collective settings"
    , collectiveInfo = "These settings apply to all users, unless overridden by personal ones. A reset loads the provided default values of the application."
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
    , userInfo = "Die persönlichen Einstellungen überschreiben die des Kollektivs. Wenn Einstellungen zurückgesetzt werden, gelten automatisch die Werte des Kollektivs."
    , collectiveHeader = "Kollektiv Einstellungen"
    , collectiveInfo = "Diese Einstellungen sind für alle Benutzer, können aber in den persönlichen Einstellungen überschrieben werden. Durch ein Zurücksetzen erhält man die bereitgestellten Standardwerte der Anwendung."
    , expandCollapse = "Alle ein-/ausklappen"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , uiSettingsForm = Messages.Comp.UiSettingsForm.fr
    , accountScope = Messages.Data.AccountScope.fr
    , saveSettings = "Enregistrer les paramètres"
    , settingsUnchanged = "Paramètres inchangés ou invalides."
    , settingsSaved = "Paramètres enregistrés."
    , unknownSaveError = "Erreur inconnue lors de l'enregistrement des paramètres."
    , httpError = Messages.Comp.HttpError.fr
    , userHeader = "Paramètres personnels"
    , userInfo = "Les paramètres personnels écrasent ceux du groupe. En cas de remise à zéro, ceux du groupe sont utilisés."
    , collectiveHeader = "Paramètres de groupe"
    , collectiveInfo = "Ces paramètres s'appliquent à tous les utilisateurs à moins d'être écrasés par les paramètres personnels. En cas de remise à zéro, les paramètres par défaut de l'application sont utilisés."
    , expandCollapse = "Étendre/Réduire tout"
    }
