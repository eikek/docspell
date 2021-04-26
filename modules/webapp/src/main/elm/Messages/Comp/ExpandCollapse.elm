module Messages.Comp.ExpandCollapse exposing
    ( Texts
    , gb
    )


type alias Texts =
    { showMoreLabel : String
    , showLessLabel : String
    }


gb : Texts
gb =
    { showMoreLabel = "Show More …"
    , showLessLabel = "Show Less …"
    }
