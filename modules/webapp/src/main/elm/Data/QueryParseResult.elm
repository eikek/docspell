{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


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
