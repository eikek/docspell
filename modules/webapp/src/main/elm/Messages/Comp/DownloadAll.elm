{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DownloadAll exposing (Texts, de, fr, gb)

import Messages.Data.DownloadFileType
import Util.Size


type alias Texts =
    { downloadFileType : Messages.Data.DownloadFileType.Texts
    , downloadFileTypeLabel : String
    , noResults : String
    , summary : Int -> String -> String
    , close : String
    , downloadPreparing : String
    , downloadTooLarge : String
    , downloadConfigText : Int -> Int -> Int -> String
    , downloadReady : String
    , downloadCreateText : String
    , downloadCreate : String
    , downloadNow : String
    }


byteStr : Int -> String
byteStr n =
    Util.Size.bytesReadable Util.Size.B (toFloat n)


gb : Texts
gb =
    { downloadFileType = Messages.Data.DownloadFileType.gb
    , downloadFileTypeLabel = "What files"
    , noResults = "No results to download."
    , summary = \files -> \size -> "Download consists of " ++ String.fromInt files ++ " files (" ++ size ++ ")."
    , close = "Close"
    , downloadPreparing = "Download is being prepared…"
    , downloadTooLarge = "The download is too large."
    , downloadConfigText =
        \maxNum ->
            \maxSize ->
                \curSize ->
                    "The maximum number of files allowed is "
                        ++ String.fromInt maxNum
                        ++ " and maximum size is "
                        ++ byteStr maxSize
                        ++ " (current size would be "
                        ++ byteStr curSize
                        ++ "). "
    , downloadReady = "Donwload is ready!"
    , downloadCreateText = "You can create the download at the server. Once it is ready, the button will download the zip file."
    , downloadCreate = "Create download"
    , downloadNow = "Download now!"
    }


de : Texts
de =
    { downloadFileType = Messages.Data.DownloadFileType.de
    , downloadFileTypeLabel = "Welche Dateien"
    , noResults = "Keine Ergebnisse zum Herunterladen."
    , summary = \files -> \size -> "Download besteht aus " ++ String.fromInt files ++ " Dateien (" ++ size ++ ")."
    , close = "Schließen"
    , downloadPreparing = "Der Download wird erstellt…"
    , downloadTooLarge = "Der Download ist zu groß."
    , downloadConfigText =
        \maxNum ->
            \maxSize ->
                \curSize ->
                    "Es können maximal "
                        ++ String.fromInt maxNum
                        ++ " Dateien mit einer Gesamtgröße von "
                        ++ byteStr maxSize
                        ++ " erstellt werden (aktuelle Größe wäre "
                        ++ byteStr curSize
                        ++ "). "
    , downloadReady = "Donwload ist fertig!"
    , downloadCreateText = "Der Download kann auf dem Server erzeugt werden. Sobald die ZIP Datei fertig ist, kann sie hier heruntergeladen werden."
    , downloadCreate = "Download erstellen"
    , downloadNow = "Jetzt herunterladen"
    }


fr : Texts
fr =
    { downloadFileType = Messages.Data.DownloadFileType.fr
    , downloadFileTypeLabel = "Quels fichiers"
    , noResults = "No results to download"
    , summary = \files -> \size -> "Download consists of " ++ String.fromInt files ++ " files (" ++ size ++ ")."
    , close = "Fermer"
    , downloadPreparing = "Le téléchargement est créé…"
    , downloadTooLarge = "Le téléchargement est trop important."
    , downloadConfigText =
        \maxNum ->
            \maxSize ->
                \curSize ->
                    "Il est possible de créer au maximum "
                        ++ String.fromInt maxNum
                        ++ " fichiers d'une taille totale de "
                        ++ byteStr maxSize
                        ++ " (la taille actuelle serait de "
                        ++ byteStr curSize
                        ++ "). "
    , downloadReady = "Le téléchargement est achevé."
    , downloadCreateText = "Vous pouvez créer le téléchargement sur le serveur. Une fois qu'il est prêt, le bouton téléchargera le fichier zip."
    , downloadCreate = "Créer Télécharger"
    , downloadNow = "Télécharger l'archive!"
    }
