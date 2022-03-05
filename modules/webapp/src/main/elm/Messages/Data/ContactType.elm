{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.ContactType exposing
    ( de
    , gb
    , fr
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

        Website ->
            "Webseite"


fr : ContactType -> String
fr ct =
    case ct of
        Phone ->
            "Téléphone"

        Mobile ->
            "Portable"

        Fax ->
            "Fax"

        Email ->
            "Email"

        Website ->
            "Web"
