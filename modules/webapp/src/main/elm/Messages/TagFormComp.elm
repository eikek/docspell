module Messages.TagFormComp exposing (..)


type alias Texts =
    { selectDefineCategory : String
    , name : String
    , category : String
    }


gb : Texts
gb =
    { selectDefineCategory = "Select or define category..."
    , name = "Name"
    , category = "Category"
    }
