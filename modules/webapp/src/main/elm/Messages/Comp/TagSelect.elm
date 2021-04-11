module Messages.Comp.TagSelect exposing (Texts, gb)


type alias Texts =
    { hideEmpty : String
    , showEmpty : String
    , filterPlaceholder : String
    }


gb : Texts
gb =
    { hideEmpty = "Hide empty"
    , showEmpty = "Show empty"
    , filterPlaceholder = "Filter …"
    }
