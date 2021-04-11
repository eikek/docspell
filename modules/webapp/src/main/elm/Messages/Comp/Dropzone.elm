module Messages.Comp.Dropzone exposing (Texts, gb)

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
