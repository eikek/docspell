module Messages.App exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { login : String
    }


gb : Texts
gb =
    { login = "Login"
    }


de : Texts
de =
    { login = "Anmelden"
    }
