module Messages.Data.PersonUse exposing
    ( de
    , gb
    )

import Data.PersonUse exposing (PersonUse(..))


gb : PersonUse -> String
gb pu =
    case pu of
        Correspondent ->
            "Correspondent"

        Concerning ->
            "Concerning"

        Both ->
            "Both"

        Disabled ->
            "Disabled"


de : PersonUse -> String
de pu =
    case pu of
        Correspondent ->
            "Korrespondent"

        Concerning ->
            "Betreffend"

        Both ->
            "Beide"

        Disabled ->
            "Deaktiviert"
