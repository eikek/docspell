module Messages.Data.OrgUse exposing (gb)

import Data.OrgUse exposing (OrgUse(..))


gb : OrgUse -> String
gb pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Disabled ->
            "Disabled"
