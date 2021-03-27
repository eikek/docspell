module Messages.FixedDropdown exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { select : String
    }


gb : Texts
gb =
    { select = "Select…"
    }


de : Texts
de =
    { select = "Auswahl…"
    }
