module Data.BoxContent exposing
    ( BoxContent(..)
    , MessageData
    , QueryData
    , SearchQuery(..)
    , StatsData
    , SummaryShow(..)
    , UploadData
    , boxContentIcon
    , emptyMessageData
    , emptyQueryData
    , emptyStatsData
    , emptyUploadData
    )

import Data.ItemColumn exposing (ItemColumn)


type BoxContent
    = BoxUpload UploadData
    | BoxMessage MessageData
    | BoxQuery QueryData
    | BoxStats StatsData


type alias MessageData =
    { title : String
    , body : String
    }


emptyMessageData : MessageData
emptyMessageData =
    { title = ""
    , body = ""
    }


type alias UploadData =
    { sourceId : Maybe String
    }


emptyUploadData : UploadData
emptyUploadData =
    { sourceId = Nothing
    }


type alias QueryData =
    { query : SearchQuery
    , limit : Int
    , details : Bool
    , columns : List ItemColumn
    , showHeaders : Bool
    }


emptyQueryData : QueryData
emptyQueryData =
    { query = SearchQueryString ""
    , limit = 5
    , details = True
    , columns = []
    , showHeaders = True
    }


type alias StatsData =
    { query : SearchQuery
    , show : SummaryShow
    }


emptyStatsData : StatsData
emptyStatsData =
    { query = SearchQueryString ""
    , show = SummaryShowGeneral
    }


type SummaryShow
    = SummaryShowFields Bool
    | SummaryShowGeneral


type SearchQuery
    = SearchQueryString String
    | SearchQueryBookmark String


boxContentIcon : BoxContent -> String
boxContentIcon content =
    case content of
        BoxMessage _ ->
            "fa fa-comment-alt font-thin"

        BoxUpload _ ->
            "fa fa-file-upload"

        BoxQuery _ ->
            "fa fa-search"

        BoxStats _ ->
            "fa fa-chart-bar font-thin"
