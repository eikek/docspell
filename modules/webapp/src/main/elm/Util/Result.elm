{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.Result exposing (combine, fold)

import Api.Model.BasicResult exposing (BasicResult)
import Set


fold : (a -> x) -> (b -> x) -> Result b a -> x
fold fa fb rba =
    case rba of
        Ok a ->
            fa a

        Err b ->
            fb b


combine : BasicResult -> BasicResult -> BasicResult
combine r1 r2 =
    BasicResult (r1.success && r2.success)
        (Set.fromList [ r1.message, r2.message ]
            |> Set.toList
            |> String.join ", "
        )
