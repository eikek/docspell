{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.SourceForm exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.Language exposing (Language)
import Messages.Basics
import Messages.Comp.TagDropdown
import Messages.Data.Language


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagDropdown : Messages.Comp.TagDropdown.Texts
    , description : String
    , enabled : String
    , priority : String
    , priorityInfo : String
    , metadata : String
    , metadataInfoText : String
    , folderInfo : String
    , tagsInfo : String
    , fileFilter : String
    , fileFilterInfo : String
    , language : String
    , languageInfo : String
    , languageLabel : Language -> String
    , attachmentsOnly : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagDropdown = Messages.Comp.TagDropdown.gb
    , description = "Description"
    , enabled = "Enabled"
    , priority = "Priority"
    , priorityInfo = "The priority used by the scheduler when processing uploaded files."
    , metadata = "Metadata"
    , metadataInfoText =
        "Metadata specified here is automatically attached to each item uploaded "
            ++ "through this source, unless it is overriden in the upload request meta data. "
            ++ "Tags from the request are added to those defined here."
    , folderInfo = "Choose a folder to automatically put items into."
    , tagsInfo = "Choose tags that should be applied to items."
    , fileFilter = "File Filter"
    , fileFilterInfo = """

Specify a file glob to filter files when uploading archives
(e.g. for email and zip). For example, to only extract pdf files:
`*.pdf`. Globs can be combined via OR, like this: `*.pdf|mail.html`.

"""
    , language = "Language"
    , languageInfo =
        "Used for text extraction and analysis. The collective's "
            ++ "default language is used if not specified here."
    , languageLabel = Messages.Data.Language.gb
    , attachmentsOnly = "Only import attachments for e-mails"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , tagDropdown = Messages.Comp.TagDropdown.de
    , description = "Beschreibung"
    , enabled = "Aktiviert"
    , priority = "Priorität"
    , priorityInfo = "Die Priorität, die für die Hintergrundaufgabe zur Verarbeitung verwendet wird."
    , metadata = "Metadaten"
    , metadataInfoText =
        "Die hier definierten Metadaten werden automatisch an das Dokument angefügt, welches durch diese "
            ++ "Quelle hochgeladen wurde. Es kann im Hochladeformular direkt nochmals überschrieben "
            ++ "oder (bei Tags) erweitert werden."
    , folderInfo = "Wähle einen Ordner mit dem die Dokumente automatisch verknüpft werden sollen."
    , tagsInfo = "Wähle Tags, die automatisch angefügt werden sollen."
    , fileFilter = "Dateifilter"
    , fileFilterInfo = """

Hier kann ein "glob" definiert werden, um nur bestimmte Dateien *aus
Archiven* (zip oder E-Mail) zu importieren und die anderen zu
ignorieren. Zum Beispiel: um nur PDF-Dateien aus E-Mails zu
importieren: `*.pdf`. Globs können auch mittels OR kombiniert werden:
`*.pdf|mail.html`.

"""
    , language = "Sprache"
    , languageInfo =
        "Wird für die Texterkennung und -analyse verwendet. Die Standardsprache des Kollektivs "
            ++ "wird verwendet, falls hier nicht angegeben."
    , languageLabel = Messages.Data.Language.de
    , attachmentsOnly = "Bei E-Mails nur die Anhänge importieren"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , tagDropdown = Messages.Comp.TagDropdown.fr
    , description = "Description"
    , enabled = "Actif"
    , priority = "Priorité"
    , priorityInfo = "Ordre de priorité utilisé par le programmateur lors du traitement des fichiers envoyés."
    , metadata = "Metadonnées"
    , metadataInfoText =
        "Les métadonnées mentionnées ici sont automatiquement assignées à chaque fichier envoyé "
            ++ "via cette source, à moins d'être écrasées par les métadonnées de la requête d'envoi."
            ++ "Les tags de la requête sont ajoutés à ceux définis ici."
    , folderInfo = "Choisir le dossier où seront déposés automatiquement les documents."
    , tagsInfo = "Choisir les tags qui seront assignés aux documents."
    , fileFilter = "Filtre de fichier"
    , fileFilterInfo = """

Spécifier un filtre type 'glob' afin de filtrer les fichiers
à l'envoi d'archives (ex: pour mail et zip). Par Example, pour
extraire uniquement les fichiers pdf: `*.pdf`.
Les filtre 'glob' peuvent être combinés avec OR, comme cela:
`.pdf|mail.html`.

"""
    , language = "Langue"
    , languageInfo =
        "Utilisé pour l'extraction et l'analyse du texte. La langue"
            ++ "par défaut du groupe est utilisée, si rien n'est spécifié ici."
    , languageLabel = Messages.Data.Language.fr
    , attachmentsOnly = "Importer uniquement les pièces-jointes pour les mails."
    }
