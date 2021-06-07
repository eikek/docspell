module Messages.Comp.ExpandCollapse exposing
    ( Texts
    , de
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


de : Texts
de =
    { showMoreLabel = "Mehr …"
    , showLessLabel = "Weniger …"
    }
