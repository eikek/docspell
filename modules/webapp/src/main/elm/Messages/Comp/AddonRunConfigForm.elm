{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.AddonRunConfigForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.CalEventInput


type alias Texts =
    { basics : Messages.Basics.Texts
    , calEventInput : Messages.Comp.CalEventInput.Texts
    , enableDisable : String
    , chooseName : String
    , impersonateUser : String
    , triggerRun : String
    , schedule : String
    , addons : String
    , includedAddons : String
    , add : String
    , readMore : String
    , readLess : String
    , arguments : String
    , update : String
    , argumentsUpdated : String
    , configureTitle : String
    , configureLabel : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , calEventInput = Messages.Comp.CalEventInput.gb tz
    , enableDisable = "Enable or disable this run configuration."
    , chooseName = "Choose a name…"
    , impersonateUser = "Run on behalf of user"
    , triggerRun = "Trigger Run"
    , schedule = "Schedule"
    , addons = "Addons"
    , includedAddons = "Included addons"
    , add = "Add"
    , readMore = "Read more"
    , readLess = "Read less"
    , arguments = "Arguments"
    , update = "Update"
    , argumentsUpdated = "Arguments updated"
    , configureTitle = "Configure this addon"
    , configureLabel = "Configure"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , calEventInput = Messages.Comp.CalEventInput.de tz
    , enableDisable = "Konfiguration aktivieren oder deaktivieren"
    , chooseName = "Name der Konfiguration…"
    , impersonateUser = "Als Benutzer ausführen"
    , triggerRun = "Auslöser"
    , schedule = "Zeitplan"
    , addons = "Addons"
    , includedAddons = "Gewählte Addons"
    , add = "Hinzufügen"
    , readMore = "Mehr"
    , readLess = "Weniger"
    , arguments = "Argumente"
    , update = "Aktualisieren"
    , argumentsUpdated = "Argumente aktualisiert"
    , configureTitle = "Konfiguriere dieses Addon"
    , configureLabel = "Konfigurieren"
    }



-- TODO: translate-fr


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , calEventInput = Messages.Comp.CalEventInput.fr tz
    , enableDisable = "Activer ou désactiver cette tâche."
    , chooseName = "Choose a name…"
    , impersonateUser = "Impersonate user"
    , triggerRun = "Trigger Run"
    , schedule = "Programmation"
    , addons = "Addons"
    , includedAddons = "Included addons"
    , add = "Ajouter"
    , readMore = "Read more"
    , readLess = "Read less"
    , arguments = "Arguments"
    , update = "Update"
    , argumentsUpdated = "Arguments updated"
    , configureTitle = "Configure this addon"
    , configureLabel = "Configure"
    }
