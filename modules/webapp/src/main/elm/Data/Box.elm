module Data.Box exposing (Box)

import Data.BoxContent exposing (BoxContent)


type alias Box =
    { name : String
    , visible : Bool
    , decoration : Bool
    , colspan : Int
    , content : BoxContent
    }
