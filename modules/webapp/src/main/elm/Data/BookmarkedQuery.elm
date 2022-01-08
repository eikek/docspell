module Data.BookmarkedQuery exposing
    ( AllBookmarks
    , BookmarkedQuery
    , BookmarkedQueryDef
    , Bookmarks
    , Location(..)
    , add
    , bookmarksDecoder
    , bookmarksEncode
    , emptyBookmarks
    , exists
    , remove
    )

import Json.Decode as D
import Json.Encode as E


type Location
    = User
    | Collective


type alias BookmarkedQuery =
    { name : String
    , query : String
    }


bookmarkedQueryDecoder : D.Decoder BookmarkedQuery
bookmarkedQueryDecoder =
    D.map2 BookmarkedQuery
        (D.field "name" D.string)
        (D.field "query" D.string)


bookmarkedQueryEncode : BookmarkedQuery -> E.Value
bookmarkedQueryEncode bq =
    E.object
        [ ( "name", E.string bq.name )
        , ( "query", E.string bq.query )
        ]


type alias BookmarkedQueryDef =
    { query : BookmarkedQuery
    , location : Location
    }


type Bookmarks
    = Bookmarks (List BookmarkedQuery)


emptyBookmarks : Bookmarks
emptyBookmarks =
    Bookmarks []


type alias AllBookmarks =
    { collective : Bookmarks
    , user : Bookmarks
    }


{-| Checks wether a bookmark of this name already exists.
-}
exists : String -> Bookmarks -> Bool
exists name bookmarks =
    case bookmarks of
        Bookmarks list ->
            List.any (\b -> b.name == name) list


remove : String -> Bookmarks -> Bookmarks
remove name bookmarks =
    case bookmarks of
        Bookmarks list ->
            Bookmarks <| List.filter (\b -> b.name /= name) list


sortByName : Bookmarks -> Bookmarks
sortByName bm =
    case bm of
        Bookmarks all ->
            Bookmarks <| List.sortBy .name all


add : BookmarkedQuery -> Bookmarks -> Bookmarks
add query bookmarks =
    case remove query.name bookmarks of
        Bookmarks all ->
            sortByName (Bookmarks (query :: all))


bookmarksDecoder : D.Decoder Bookmarks
bookmarksDecoder =
    D.maybe
        (D.field "bookmarks"
            (D.list bookmarkedQueryDecoder
                |> D.map Bookmarks
                |> D.map sortByName
            )
        )
        |> D.map (Maybe.withDefault emptyBookmarks)


bookmarksEncode : Bookmarks -> E.Value
bookmarksEncode bookmarks =
    case bookmarks of
        Bookmarks all ->
            E.object
                [ ( "bookmarks", E.list bookmarkedQueryEncode all )
                ]
