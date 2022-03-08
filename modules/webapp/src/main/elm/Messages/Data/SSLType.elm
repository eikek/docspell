{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.SSLType exposing
    ( de
    , gb
    , fr
    )

import Data.SSLType exposing (SSLType(..))


gb : SSLType -> String
gb st =
    case st of
        None ->
            "None"

        SSL ->
            "SSL/TLS"

        StartTLS ->
            "StartTLS"


de : SSLType -> String
de st =
    case st of
        None ->
            "Keine"

        SSL ->
            "SSL/TLS"

        StartTLS ->
            "StartTLS"

fr : SSLType -> String
fr st =
    case st of
        None ->
            "Aucun"

        SSL ->
            "SSL/TLS"

        StartTLS ->
            "StartTLS"

