{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.File exposing (makeFileId)

import File exposing (File)
import Util.String


makeFileId : File -> String
makeFileId file =
    File.name file
        ++ "-"
        ++ (File.size file |> String.fromInt)
        |> Util.String.crazyEncode
