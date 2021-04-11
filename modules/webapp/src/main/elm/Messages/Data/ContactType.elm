module Messages.Data.ContactType exposing (gb)

import Data.ContactType exposing (ContactType(..))


gb : ContactType -> String
gb ct =
    case ct of
        Phone ->
            "Phone"

        Mobile ->
            "Mobile"

        Fax ->
            "Fax"

        Email ->
            "Email"

        Docspell ->
            "Docspell"

        Website ->
            "Website"
