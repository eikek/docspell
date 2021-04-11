module Messages.Comp.Dropzone exposing (Texts, gb)


type alias Texts =
    { dropFilesHere : String
    , or : String
    , select : String
    , selectInfo : String
    }


gb : Texts
gb =
    { dropFilesHere = "Drop files here"
    , or = "Or"
    , select = "Select ..."
    , selectInfo =
        "Choose document files (pdf, docx, txt, html, …). "
            ++ "Archives (zip and eml) are extracted."
    }
