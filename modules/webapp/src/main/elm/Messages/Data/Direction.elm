module Messages.Data.Direction exposing (gb)

import Data.Direction exposing (Direction(..))


gb : Direction -> String
gb dir =
    case dir of
        Incoming ->
            "Incoming"

        Outgoing ->
            "Outgoing"
