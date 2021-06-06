module Messages.Data.OrgUse exposing
    ( de
    , gb
    )

import Data.OrgUse exposing (OrgUse(..))


gb : OrgUse -> String
gb pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Disabled ->
            "Disabled"


de : OrgUse -> String
de pu =
    case pu of
        Correspondent ->
            "Korrespondent"

        Disabled ->
            "Deaktiviert"
