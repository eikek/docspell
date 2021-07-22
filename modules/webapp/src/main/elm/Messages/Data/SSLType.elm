{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Data.SSLType exposing
    ( de
    , gb
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
