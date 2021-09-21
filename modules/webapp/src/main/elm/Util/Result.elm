{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.Result exposing (fold)


fold : (a -> x) -> (b -> x) -> Result b a -> x
fold fa fb rba =
    case rba of
        Ok a ->
            fa a

        Err b ->
            fb b
