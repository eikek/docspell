module Data.BoxContent exposing
    ( BoxContent(..)
    , MessageData
    , QueryData
    , SearchQuery(..)
    , SummaryData
    , SummaryShow(..)
    )

import Data.ItemTemplate exposing (ItemTemplate)


type BoxContent
    = BoxUpload (Maybe String)
    | BoxMessage MessageData
    | BoxQuery QueryData
    | BoxSummary SummaryData


type alias MessageData =
    { title : String
    , body : String
    }


type alias QueryData =
    { query : SearchQuery
    , limit : Int
    , details : Bool
    , header : List String
    , columns : List ItemTemplate
    }


type alias SummaryData =
    { query : SearchQuery
    , show : SummaryShow
    }


type SummaryShow
    = SummaryShowFields Bool
    | SummaryShowGeneral


type SearchQuery
    = SearchQueryString String
    | SearchQueryBookmark String
