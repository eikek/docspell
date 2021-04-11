module Messages.Comp.TagForm exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , selectDefineCategory : String
    , category : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , selectDefineCategory = "Select or define category..."
    , category = "Category"
    }
