module Data.BoxContent exposing (BoxContent(..), MessageData, QueryData, SummaryData)

import Data.ItemArrange exposing (ItemArrange)


type BoxContent
    = BoxUpload
    | BoxMessage MessageData
    | BoxQuery QueryData
    | BoxSummary SummaryData


type alias MessageData =
    { title : String
    , body : String
    }


type alias QueryData =
    { query : String
    , view : ItemArrange
    }


type alias SummaryData =
    { query : String
    }
