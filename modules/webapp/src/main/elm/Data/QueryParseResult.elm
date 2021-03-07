module Data.QueryParseResult exposing (QueryParseResult, success)


type alias QueryParseResult =
    { success : Bool
    , input : String
    , index : Int
    , messages : List String
    }


success : QueryParseResult
success =
    QueryParseResult True "" 0 []
