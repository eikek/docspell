{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.SearchStatsView exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { items : String
    , count : String
    , sum : String
    , avg : String
    , min : String
    , max : String
    }


gb : Texts
gb =
    { items = "Items"
    , count = "Count"
    , sum = "Sum"
    , avg = "Avg"
    , min = "Min"
    , max = "Max"
    }


de : Texts
de =
    { items = "Dokumente"
    , count = "Anzahl"
    , sum = "Summe"
    , avg = "Durchschnitt"
    , min = "Minimum"
    , max = "Maximum"
    }
