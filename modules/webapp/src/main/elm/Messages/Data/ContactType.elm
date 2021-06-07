module Messages.Data.ContactType exposing
    ( de
    , gb
    )

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


de : ContactType -> String
de ct =
    case ct of
        Phone ->
            "Telefon"

        Mobile ->
            "Mobil"

        Fax ->
            "Fax"

        Email ->
            "E-Mail"

        Docspell ->
            "Docspell"

        Website ->
            "Webseite"
