module Messages.Comp.CollectiveSettingsForm exposing
    ( Texts
    , de
    , gb
    )

import Data.Language exposing (Language)
import Http
import Messages.Basics
import Messages.Comp.ClassifierSettingsForm
import Messages.Comp.HttpError
import Messages.Data.Language


type alias Texts =
    { basics : Messages.Basics.Texts
    , classifierSettingsForm : Messages.Comp.ClassifierSettingsForm.Texts
    , httpError : Http.Error -> String
    , save : String
    , saveSettings : String
    , documentLanguage : String
    , documentLanguageHelp : String
    , integrationEndpoint : String
    , integrationEndpointLabel : String
    , integrationEndpointHelp : String
    , fulltextSearch : String
    , reindexAllData : String
    , reindexAllDataHelp : String
    , autoTagging : String
    , startNow : String
    , languageLabel : Language -> String
    , classifierTaskStarted : String
    , fulltextReindexSubmitted : String
    , fulltextReindexOkMissing : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , classifierSettingsForm = Messages.Comp.ClassifierSettingsForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , save = "Save"
    , saveSettings = "Save Settings"
    , documentLanguage = "Document Language"
    , documentLanguageHelp = "The language of your documents. This helps text recognition (OCR) and text analysis."
    , integrationEndpoint = "Integration Endpoint"
    , integrationEndpointLabel = "Enable integration endpoint"
    , integrationEndpointHelp =
        "The integration endpoint allows (local) applications to submit files. "
            ++ "You can choose to disable it for your collective."
    , fulltextSearch = "Full-Text Search"
    , reindexAllData = "Re-Index All Data"
    , reindexAllDataHelp =
        "This starts a task that clears the full-text index and re-indexes all your data again."
            ++ "You must type OK before clicking the button to avoid accidental re-indexing."
    , autoTagging = "Auto-Tagging"
    , startNow = "Start now"
    , languageLabel = Messages.Data.Language.gb
    , classifierTaskStarted = "Classifier task started."
    , fulltextReindexSubmitted = "Fulltext Re-Index started."
    , fulltextReindexOkMissing =
        "Please type OK in the field if you really want to start re-indexing your data."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , classifierSettingsForm = Messages.Comp.ClassifierSettingsForm.de
    , httpError = Messages.Comp.HttpError.de
    , save = "Speichern"
    , saveSettings = "Einstellungen speichern"
    , documentLanguage = "Sprache"
    , documentLanguageHelp = "Die Sprache der Dokumente. Das hilft der Texterkennung (OCR) und -analyse."
    , integrationEndpoint = "Integrationsendpunkt"
    , integrationEndpointLabel = "Aktiviere den Integrationsendpunkt"
    , integrationEndpointHelp =
        "Der Integrationsendpunkt erlaubt es (lokalen) Anwendungen Dateien einzustellen. "
            ++ "Dies kann für dieses Kollektiv de-/aktiviert werden."
    , fulltextSearch = "Volltextsuche"
    , reindexAllData = "Alle Daten neu indexieren"
    , reindexAllDataHelp =
        "Der Index wird im Hintergrund gelöscht und alle Daten neu indexiert. "
            ++ "Bitte tippe vor dem Klicken OK ein, um ein versehentliches erneutes Indexieren zu vermeiden."
    , autoTagging = "Automatisches Taggen"
    , startNow = "Jetzt starten"
    , languageLabel = Messages.Data.Language.de
    , classifierTaskStarted = "Kategorisierung gestartet."
    , fulltextReindexSubmitted = "Volltext Neu-Indexierung gestartet."
    , fulltextReindexOkMissing =
        "Bitte tippe OK in das Feld ein, wenn Du wirklich den Index neu erzeugen möchtest."
    }
