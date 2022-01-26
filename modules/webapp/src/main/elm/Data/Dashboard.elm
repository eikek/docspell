module Data.Dashboard exposing (Dashboard)

import Data.Box exposing (Box)


type alias Dashboard =
    { name : String
    , columns : Int
    , boxes : List Box
    }
