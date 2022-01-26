{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Dashboard exposing (Dashboard, decoder, empty, encode, isEmpty)

import Data.Box exposing (Box)
import Json.Decode as D
import Json.Encode as E


type alias Dashboard =
    { name : String
    , columns : Int
    , gap : Int
    , boxes : List Box
    }


empty : Dashboard
empty =
    { name = ""
    , columns = 1
    , gap = 2
    , boxes = []
    }


isEmpty : Dashboard -> Bool
isEmpty board =
    List.isEmpty board.boxes



--- JSON


encode : Dashboard -> E.Value
encode b =
    E.object
        [ ( "name", E.string b.name )
        , ( "columns", E.int b.columns )
        , ( "gap", E.int b.gap )
        , ( "boxes", E.list Data.Box.encode b.boxes )
        ]


decoder : D.Decoder Dashboard
decoder =
    D.map4 Dashboard
        (D.field "name" D.string)
        (D.field "columns" D.int)
        (D.field "gap" D.int)
        (D.field "boxes" <| D.list Data.Box.decoder)
