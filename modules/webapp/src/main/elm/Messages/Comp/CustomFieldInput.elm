module Messages.Comp.CustomFieldInput exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { errorNoValue : String
    , errorNoNumber : String
    , errorNoAmount : String
    , errorNotANumber : String -> String
    }


gb : Texts
gb =
    { errorNoValue = "Please fill in some value"
    , errorNoNumber = "No number given"
    , errorNoAmount = "No amount given"
    , errorNotANumber = \str -> "Not a number: " ++ str
    }


de : Texts
de =
    { errorNoValue = "Bitte gib einen Wert an"
    , errorNoNumber = "Keine Zahl angegeben"
    , errorNoAmount = "Kein Betrag angegeben"
    , errorNotANumber = \str -> "Keine Zahl: " ++ str
    }
