module Messages.SearchStatsViewComp exposing (..)


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
