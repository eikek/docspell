{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.Dropzone exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , dropFilesHere : String
    , or : String
    , selectInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , dropFilesHere = "Drop files here"
    , or = "Or"
    , selectInfo =
        "Choose document files (pdf, docx, txt, html, …). "
            ++ "Archives (zip and eml) are extracted."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , dropFilesHere = "Dateien hier hineinziehen"
    , or = "Oder"
    , selectInfo =
        "Dateien auswählen (pdf, docx, txt, html, …). "
            ++ "Archive (zip und eml) werden extrahiert."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , dropFilesHere = "Déposer les fichiers ici"
    , or = "Ou"
    , selectInfo =
        "Choisir un fichier (pdf, docx, txt, html, ...)."
            ++ "Les archives (zip et eml) seront extraites."
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , dropFilesHere = "ここにファイルをドロップ"
    , or = "または"
    , selectInfo = "文書ファイル（pdf, docx, txt, html, …）を選択してください。 "
            ++ "Archives (zip and eml) are extracted."
    }
