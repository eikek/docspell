{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CollectiveSettingsForm exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Data.Language exposing (Language)
import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.ClassifierSettingsForm
import Messages.Comp.EmptyTrashForm
import Messages.Comp.HttpError
import Messages.Data.Language


type alias Texts =
    { basics : Messages.Basics.Texts
    , classifierSettingsForm : Messages.Comp.ClassifierSettingsForm.Texts
    , emptyTrashForm : Messages.Comp.EmptyTrashForm.Texts
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
    , emptyTrashTaskStarted : String
    , emptyTrashStartInvalidForm : String
    , fulltextReindexSubmitted : String
    , fulltextReindexOkMissing : String
    , emptyTrash : String
    , passwords : String
    , passwordsInfo : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , classifierSettingsForm = Messages.Comp.ClassifierSettingsForm.gb tz
    , emptyTrashForm = Messages.Comp.EmptyTrashForm.gb tz
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
    , emptyTrashTaskStarted = "Empty trash task started."
    , emptyTrashStartInvalidForm = "The empty-trash form contains errors."
    , fulltextReindexSubmitted = "Fulltext Re-Index started."
    , fulltextReindexOkMissing =
        "Please type OK in the field if you really want to start re-indexing your data."
    , emptyTrash = "Empty Trash"
    , passwords = "Passwords"
    , passwordsInfo = "These passwords are used when encrypted PDFs are being processed. Please note, that they are stored in the database as **plain text**!"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , classifierSettingsForm = Messages.Comp.ClassifierSettingsForm.de tz
    , emptyTrashForm = Messages.Comp.EmptyTrashForm.de tz
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
    , emptyTrashTaskStarted = "Papierkorb löschen gestartet."
    , emptyTrashStartInvalidForm = "Das Papierkorb-Löschen Formular ist fehlerhaft!"
    , fulltextReindexSubmitted = "Volltext Neu-Indexierung gestartet."
    , fulltextReindexOkMissing =
        "Bitte tippe OK in das Feld ein, wenn Du wirklich den Index neu erzeugen möchtest."
    , emptyTrash = "Papierkorb löschen"
    , passwords = "Passwörter"
    , passwordsInfo = "Diese Passwörter werden zum Lesen von verschlüsselten PDFs verwendet. Diese Passwörter werden in der Datanbank **in Klartext** gespeichert!"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , classifierSettingsForm = Messages.Comp.ClassifierSettingsForm.fr tz
    , emptyTrashForm = Messages.Comp.EmptyTrashForm.fr tz
    , httpError = Messages.Comp.HttpError.fr
    , save = "Enregistrer"
    , saveSettings = "Enregistrer la configuration"
    , documentLanguage = "Langue du document"
    , documentLanguageHelp = "La langue de vos documents. Cela aide la reconnaissance de caractères (OCR) et l'analyse de texte."
    , integrationEndpoint = "Integration Endpoint"
    , integrationEndpointLabel = "Activer integration endpoint"
    , integrationEndpointHelp =
        "L'Integration Endpoint permet aux applications (locales) d'envoyer des fichiers. "
            ++ "Il peut être désactivé pour le groupe."
    , fulltextSearch = "Recherche en texte intégral"
    , reindexAllData = "Réindexer les documents"
    , reindexAllDataHelp =
        "Ceci démarrera une tâche qui effacera l'index de recherche en texte intégral et réindexera tous les documents."
            ++ "Veuillez presser OK afin d'éviter toute réindexation accidentelle."
    , autoTagging = "Auto-Tagging"
    , startNow = "Commencer"
    , languageLabel = Messages.Data.Language.fr
    , classifierTaskStarted = "Tâche de classement démarrée."
    , emptyTrashTaskStarted = "Vidange de la corbeille démarrée."
    , emptyTrashStartInvalidForm = "Le formulaire de vidange de la corbeille contient des erreurs."
    , fulltextReindexSubmitted = "Réindexation de la recherche en texte intégral démarrée."
    , fulltextReindexOkMissing =
        "Veuillez presser OK pour confirmer le lancement de la réindexation des documents."
    , emptyTrash = "Vider la corbeille"
    , passwords = "Mots de passe"
    , passwordsInfo = "Ces mots de passes sont utilisés pour le traitement des PDF encryptés. Veuillez noter qu'ils sont stockés dans la base de donnée en **clair**!"
    }


pt : TimeZone -> Texts
pt tz =
    { basics = Messages.Basics.pt
    , classifierSettingsForm = Messages.Comp.ClassifierSettingsForm.pt tz
    , emptyTrashForm = Messages.Comp.EmptyTrashForm.pt tz
    , httpError = Messages.Comp.HttpError.pt
    , save = "Salvar"
    , saveSettings = "Salvar configurações"
    , documentLanguage = "Idioma do documento"
    , documentLanguageHelp = "O idioma dos seus documentos. Isso auxilia no reconhecimento de texto (OCR) e na análise de texto."
    , integrationEndpoint = "Endpoint de integração"
    , integrationEndpointLabel = "Habilitar endpoint de integração"
    , integrationEndpointHelp =
        "O endpoint de integração permite que aplicativos (locais) enviem arquivos. "
            ++ "You can choose to disable it for your collective."
    , fulltextSearch = "Busca em texto completo"
    , reindexAllData = "Reindexar todos os dados"
    , reindexAllDataHelp =
        "Isso inicia uma tarefa que limpa o índice de texto completo e reindexa todos os seus dados novamente."
            ++ "You must type OK before clicking the button to avoid accidental re-indexing."
    , autoTagging = "Etiquetagem automática"
    , startNow = "Iniciar agora"
    , languageLabel = Messages.Data.Language.pt
    , classifierTaskStarted = "Tarefa do classificador iniciada."
    , emptyTrashTaskStarted = "Tarefa de esvaziamento da lixeira iniciada."
    , emptyTrashStartInvalidForm = "O formulário para esvaziar a lixeira contém erros."
    , fulltextReindexSubmitted = "Reindexação de texto completo iniciada."
    , fulltextReindexOkMissing =
        "Por favor, digite OK no campo se realmente deseja iniciar a reindexação dos seus dados."
    , emptyTrash = "Esvaziar lixeira"
    , passwords = "Senhas"
    , passwordsInfo = "Estas senhas são usadas quando PDFs criptografados estão sendo processados. Observe que elas são armazenadas no banco de dados como **texto sem formatação**!"
    }
