{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.Dropzone exposing
    ( Texts
    , de
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
