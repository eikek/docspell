{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AddonRunConfigManage exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.AddonRunConfigForm
import Messages.Comp.AddonRunConfigTable
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , addonArchiveTable : Messages.Comp.AddonRunConfigTable.Texts
    , addonArchiveForm : Messages.Comp.AddonRunConfigForm.Texts
    , httpError : Http.Error -> String
    , newAddonRunConfig : String
    , reallyDeleteAddonRunConfig : String
    , createNewAddonRunConfig : String
    , deleteThisAddonRunConfig : String
    , correctFormErrors : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , addonArchiveTable = Messages.Comp.AddonRunConfigTable.gb
    , addonArchiveForm = Messages.Comp.AddonRunConfigForm.gb tz
    , httpError = Messages.Comp.HttpError.gb
    , newAddonRunConfig = "New"
    , reallyDeleteAddonRunConfig = "Really delete this run config?"
    , createNewAddonRunConfig = "Create a new run configuration"
    , deleteThisAddonRunConfig = "Delete this run configuration"
    , correctFormErrors = "Please correct the errors in the form."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , addonArchiveTable = Messages.Comp.AddonRunConfigTable.de
    , addonArchiveForm = Messages.Comp.AddonRunConfigForm.de tz
    , httpError = Messages.Comp.HttpError.de
    , newAddonRunConfig = "Neu"
    , reallyDeleteAddonRunConfig = "Dieses Konfiguration wirklich entfernen?"
    , createNewAddonRunConfig = "Neue Run-Konfiguration erstellen"
    , deleteThisAddonRunConfig = "Run-Konfiguration löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }



--- TODO translate-fr


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , addonArchiveTable = Messages.Comp.AddonRunConfigTable.fr
    , addonArchiveForm = Messages.Comp.AddonRunConfigForm.fr tz
    , httpError = Messages.Comp.HttpError.fr
    , newAddonRunConfig = "Nouveau favori"
    , reallyDeleteAddonRunConfig = "Confirmer la suppression de ce favori ?"
    , createNewAddonRunConfig = "Créer un nouveau favori"
    , deleteThisAddonRunConfig = "Supprimer ce favori"
    , correctFormErrors = "Veuillez corriger les erreurs du formulaire"
    }
