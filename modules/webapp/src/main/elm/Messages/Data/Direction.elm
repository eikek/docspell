module Messages.Data.Direction exposing
    ( de
    , gb
    )

import Data.Direction exposing (Direction(..))


gb : Direction -> String
gb dir =
    case dir of
        Incoming ->
            "Incoming"

        Outgoing ->
            "Outgoing"


de : Direction -> String
de dir =
    case dir of
        Incoming ->
            "Eingehend"

        Outgoing ->
            "Ausgehend"
