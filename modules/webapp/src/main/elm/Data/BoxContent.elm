module Data.BoxContent exposing
    ( BoxContent(..)
    , MessageData
    , QueryData
    , SearchQuery(..)
    , StatsData
    , SummaryShow(..)
    , UploadData
    , boxContentDecoder
    , boxContentEncode
    , boxContentIcon
    , emptyMessageData
    , emptyQueryData
    , emptyStatsData
    , emptyUploadData
    )

import Data.ItemColumn exposing (ItemColumn)
import Html exposing (datalist)
import Json.Decode as D
import Json.Encode as E


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


searchQueryAsString : SearchQuery -> String
searchQueryAsString q =
    case q of
        SearchQueryBookmark id ->
            "bookmark:" ++ id

        SearchQueryString str ->
            "query:" ++ str


searchQueryFromString : String -> Maybe SearchQuery
searchQueryFromString str =
    if String.startsWith "bookmark:" str then
        Just (SearchQueryBookmark <| String.dropLeft 9 str)

    else if String.startsWith "query:" str then
        Just (SearchQueryString <| String.dropLeft 6 str)

    else
        Nothing


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



--- JSON


boxContentDecoder : D.Decoder BoxContent
boxContentDecoder =
    let
        from discr =
            case String.toLower discr of
                "message" ->
                    D.field "data" <|
                        D.map BoxMessage messageDataDecoder

                "upload" ->
                    D.field "data" <|
                        D.map BoxUpload uploadDataDecoder

                "query" ->
                    D.field "data" <|
                        D.map BoxQuery queryDataDecoder

                "stats" ->
                    D.field "data" <|
                        D.map BoxStats statsDataDecoder

                _ ->
                    D.fail ("Unknown box content: " ++ discr)
    in
    D.andThen from (D.field discriminator D.string)


boxContentEncode : BoxContent -> E.Value
boxContentEncode cnt =
    case cnt of
        BoxMessage data ->
            E.object
                [ ( discriminator, E.string "message" )
                , ( "data", messageDataEncode data )
                ]

        BoxUpload data ->
            E.object
                [ ( discriminator, E.string "upload" )
                , ( "data", uploadDataEncode data )
                ]

        BoxQuery data ->
            E.object
                [ ( discriminator, E.string "query" )
                , ( "data", queryDataEncode data )
                ]

        BoxStats data ->
            E.object
                [ ( discriminator, E.string "stats" )
                , ( "data", statsDataEncode data )
                ]


messageDataDecoder : D.Decoder MessageData
messageDataDecoder =
    D.map2 MessageData
        (D.field "title" D.string)
        (D.field "body" D.string)


messageDataEncode : MessageData -> E.Value
messageDataEncode data =
    E.object
        [ ( "title", E.string data.title )
        , ( "body", E.string data.body )
        ]


uploadDataDecoder : D.Decoder UploadData
uploadDataDecoder =
    D.map UploadData
        (D.maybe (D.field "sourceId" D.string))


uploadDataEncode : UploadData -> E.Value
uploadDataEncode data =
    E.object
        [ ( "sourceId", Maybe.map E.string data.sourceId |> Maybe.withDefault E.null )
        ]


queryDataDecoder : D.Decoder QueryData
queryDataDecoder =
    D.map5 QueryData
        (D.field "query" searchQueryDecoder)
        (D.field "limit" D.int)
        (D.field "details" D.bool)
        (D.field "columns" <| D.list Data.ItemColumn.decode)
        (D.field "showHeaders" D.bool)


queryDataEncode : QueryData -> E.Value
queryDataEncode data =
    E.object
        [ ( "query", searchQueryEncode data.query )
        , ( "limit", E.int data.limit )
        , ( "details", E.bool data.details )
        , ( "columns", E.list Data.ItemColumn.encode data.columns )
        , ( "showHeaders", E.bool data.showHeaders )
        ]


statsDataDecoder : D.Decoder StatsData
statsDataDecoder =
    D.map2 StatsData
        (D.field "query" searchQueryDecoder)
        (D.field "show" summaryShowDecoder)


statsDataEncode : StatsData -> E.Value
statsDataEncode data =
    E.object
        [ ( "query", searchQueryEncode data.query )
        , ( "show", summaryShowEncode data.show )
        ]


searchQueryDecoder : D.Decoder SearchQuery
searchQueryDecoder =
    let
        fromString str =
            case searchQueryFromString str of
                Just q ->
                    D.succeed q

                Nothing ->
                    D.fail ("Invalid search query: " ++ str)
    in
    D.andThen fromString D.string


searchQueryEncode : SearchQuery -> E.Value
searchQueryEncode q =
    E.string (searchQueryAsString q)


summaryShowDecoder : D.Decoder SummaryShow
summaryShowDecoder =
    let
        decode discr =
            case String.toLower discr of
                "fields" ->
                    D.field "showItemCount" D.bool
                        |> D.map SummaryShowFields

                "general" ->
                    D.succeed SummaryShowGeneral

                _ ->
                    D.fail ("Unknown summary show for: " ++ discr)
    in
    D.andThen decode (D.field discriminator D.string)


summaryShowEncode : SummaryShow -> E.Value
summaryShowEncode show =
    case show of
        SummaryShowFields flag ->
            E.object
                [ ( discriminator, E.string "fields" )
                , ( "showItemCount", E.bool flag )
                ]

        SummaryShowGeneral ->
            E.object
                [ ( "discriminator", E.string "general" )
                ]


discriminator : String
discriminator =
    "discriminator"
