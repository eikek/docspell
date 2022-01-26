{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Bookmarks exposing
    ( AllBookmarks
    , Bookmarks
    , bookmarksDecoder
    , empty
    , exists
    , findById
    , sort
    )

import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Api.Model.ShareDetail exposing (ShareDetail)
import Json.Decode as D


type alias AllBookmarks =
    { bookmarks : List BookmarkedQuery
    , shares : List ShareDetail
    }


empty : AllBookmarks
empty =
    AllBookmarks [] []


type alias Bookmarks =
    List BookmarkedQuery


findById : String -> Bookmarks -> Maybe BookmarkedQuery
findById id all =
    List.filter (\e -> e.id == id) all
        |> List.head


{-| Checks wether a bookmark of this name already exists.
-}
exists : String -> Bookmarks -> Bool
exists name bookmarks =
    List.any (\b -> b.name == name) bookmarks


sort : Bookmarks -> Bookmarks
sort bms =
    let
        labelName b =
            Maybe.withDefault b.name b.label
    in
    List.sortBy labelName bms


bookmarksDecoder : D.Decoder Bookmarks
bookmarksDecoder =
    D.list Api.Model.BookmarkedQuery.decoder
