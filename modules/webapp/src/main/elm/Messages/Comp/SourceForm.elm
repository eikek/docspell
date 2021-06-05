module Messages.Comp.SourceForm exposing
    ( Texts
    , de
    , gb
    )

import Data.Language exposing (Language)
import Messages.Basics
import Messages.Data.Language


type alias Texts =
    { basics : Messages.Basics.Texts
    , description : String
    , enabled : String
    , priority : String
    , priorityInfo : String
    , metadata : String
    , metadataInfoText : String
    , folderInfo : String
    , folderForbiddenText : String
    , tagsInfo : String
    , fileFilter : String
    , fileFilterInfo : String
    , language : String
    , languageInfo : String
    , languageLabel : Language -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
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
    , folderForbiddenText =
        """
You are **not a member** of this folder. Items created through this
link will be **hidden** from any search results. Use a folder where
you are a member of to make items visible. This message will
disappear then.
                      """
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
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , description = "Beschreibung"
    , enabled = "Aktiviert"
    , priority = "Priorität"
    , priorityInfo = "Die Priorität, die für die Hintergrund-Jobs zur Verarbeitung der Dokument verwendet wird."
    , metadata = "Metadaten"
    , metadataInfoText =
        "Die hier definierten Metadaten werden automatisch an das Dokument angefügt, was durch diese "
            ++ "Quelle hochgeladen wurde. Es kann im Upload-Request direkt nochmals überschrieben "
            ++ "oder (bei Tags) erweitert werden."
    , folderInfo = "Wähle einen Ordner; Dokumente werden automatisch damit verknüpft."
    , folderForbiddenText =
        """
Du bist *kein* Mitglied dieses Ordners. Dokumnte, welche durch diese
URL hochgeladen werden, sind für dich in der Suche *nicht* sichtbar.
Nutze lieber einen Ordner, dem Du als Mitglied zugeordnet bist. Diese
Nachricht verschwindet dann.
"""
    , tagsInfo = "Wähle Tags, die automatisch angefügt werden sollen."
    , fileFilter = "Datei Filter"
    , fileFilterInfo = """

Hier kann ein "glob" definiert werden, um nur bestimmte Dateien *aus
Archiven* (zip oder E-Mail) zu importieren und die anderen zu
ignorieren. Zum Beispiel: um nur PDF Dateien aus E-Mails zu
importieren: `*.pdf`. Globs können auch via OR kombiniert werden:
`*.pdf|mail.html`.

"""
    , language = "Sprache"
    , languageInfo =
        "Wird für Text-Extraktion und -Analyse verwendet. Die Standard-Sprache des Kollektivs "
            ++ "wird verwendet, falls hier nicht angegeben."
    , languageLabel = Messages.Data.Language.de
    }
