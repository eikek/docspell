module Messages.Comp.ItemDetail.Notes exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , notes : String
    , preview : String
    , supportsMarkdown : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notes = "Notes"
    , preview = "Preview"
    , supportsMarkdown = "Supports Markdown"
    }
