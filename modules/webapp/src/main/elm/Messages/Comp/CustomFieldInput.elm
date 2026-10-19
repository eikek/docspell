{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.CustomFieldInput exposing
    ( Texts
    , de
    , fr
    , ja
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


fr : Texts
fr =
    { errorNoValue = "remplir avec une valeur"
    , errorNoNumber = "Pas de nombre donné"
    , errorNoAmount = "Pas de montant donné"
    , errorNotANumber = \str -> "Pas un nombre: " ++ str
    }


ja : Texts
ja =
    { errorNoValue = "値を入力してください"
    , errorNoNumber = "番号が指定されていません"
    , errorNoAmount = "金額が指定されていません"
    , errorNotANumber = \str -> "Not a number: " ++ str
    }
