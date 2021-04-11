module Messages.Data.SSLType exposing (gb)

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
