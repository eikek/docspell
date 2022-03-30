{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.UploadForm exposing (Texts, de, fr, gb)

import Data.Language exposing (Language)
import Messages.Basics
import Messages.Comp.Dropzone
import Messages.Data.Language


type alias Texts =
    { basics : Messages.Basics.Texts
    , dropzone : Messages.Comp.Dropzone.Texts
    , reset : String
    , allFilesOneItem : String
    , skipExistingFiles : String
    , language : String
    , languageInfo : String
    , uploadErrorMessage : String
    , successBox :
        { allFilesUploaded : String
        , line1 : String
        , itemsPage : String
        , line2 : String
        , processingPage : String
        , line3 : String
        , resetLine1 : String
        , reset : String
        , resetLine2 : String
        }
    , selectedFiles : String
    , languageLabel : Language -> String
    , flattenArchives : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , dropzone = Messages.Comp.Dropzone.gb
    , reset = "Reset"
    , allFilesOneItem = "All files are one single item"
    , skipExistingFiles = "Skip files already present in docspell"
    , language = "Language"
    , languageInfo =
        "Used for text extraction and analysis. The collective's "
            ++ "default language is used if not specified here."
    , uploadErrorMessage = "There were errors uploading some files."
    , successBox =
        { allFilesUploaded = "All files uploaded"
        , line1 =
            "Your files have been successfully uploaded. "
                ++ "They are now being processed. Check the "
        , itemsPage = "Items Page"
        , line2 = " later where the files will arrive eventually. Or go to the "
        , processingPage = "Processing Page"
        , line3 = " to view the current processing state."
        , resetLine1 = " Click "
        , reset = "Reset"
        , resetLine2 = " to upload more files."
        }
    , selectedFiles = "Selected Files"
    , languageLabel = Messages.Data.Language.gb
    , flattenArchives = "Extract zip file contents into separate items, in contrast to a single document with multiple attachments."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , dropzone = Messages.Comp.Dropzone.de
    , reset = "Zurücksetzen"
    , allFilesOneItem = "Alle Dateien sind ein Dokument"
    , skipExistingFiles = "Lasse Dateien aus, die schon in Docspell sind"
    , language = "Sprache"
    , languageInfo =
        "Wird für Texterkennung und -analyse verwendet. Die Standardsprache des Kollektivs "
            ++ "wird verwendet, falls hier nicht angegeben."
    , uploadErrorMessage = "Es gab Fehler beim Hochladen der Dateien."
    , successBox =
        { allFilesUploaded = "Alle Dateien hochgeladen"
        , line1 =
            "Deine Dateien wurden erfolgreich hochgeladen und sie werden nun verarbeitet. "
                ++ "Gehe nachher zur "
        , itemsPage = "Hauptseite"
        , line2 = " wo die Dateien als Dokumente erscheinen werden oder gehe zur "
        , processingPage = "Verarbeitungsseite,"
        , line3 = " welche einen Einblick in den aktuellen Status gibt."
        , resetLine1 = " Klicke "
        , reset = "Zurücksetzen"
        , resetLine2 = " um weitere Dateien hochzuladen."
        }
    , selectedFiles = "Ausgewählte Dateien"
    , languageLabel = Messages.Data.Language.de
    , flattenArchives = "ZIP Dateien in separate Dokumente entpacken, anstatt ein Dokument mit mehreren Anhängen."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , dropzone = Messages.Comp.Dropzone.fr
    , reset = "Recommencer"
    , allFilesOneItem = "Tous les fichiers ne sont qu'un seul document"
    , skipExistingFiles = "Ignorer les fichiers déjà présents dans docspell"
    , language = "Langue"
    , languageInfo =
        "Utilisé pour l'extraction et l'analyse. Le langage par défaut"
            ++ "du groupe est utilisé si rien n'est spécifié."
    , uploadErrorMessage = "Erreurs lors du transfert des fichiers."
    , successBox =
        { allFilesUploaded = "Tous les transferts sont complétés."
        , line1 =
            "Les fichiers ont bien été envoyés"
                ++ "Ils sont en cours de traitement.  Rendez-vous aux"
        , itemsPage = "Documents"
        , line2 = " plus tard où les fichiers arrivent. Où rendez-vous à la "
        , processingPage = "File de traitement"
        , line3 = " afin de voir l'état du traitement."
        , resetLine1 = " Cliquer sur "
        , reset = "Recommencer"
        , resetLine2 = " pour envoyer plus de fichier."
        }
    , selectedFiles = "Fichiers séléctionnés"
    , languageLabel = Messages.Data.Language.fr
    , flattenArchives = "Décompresser les fichiers ZIP dans des documents séparés au lieu de créer un document avec plusieurs pièces jointes."
    }
