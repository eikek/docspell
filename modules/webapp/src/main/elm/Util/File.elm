module Util.File exposing (makeFileId)

import File exposing (File)
import Util.String


makeFileId : File -> String
makeFileId file =
    File.name file
        ++ "-"
        ++ (File.size file |> String.fromInt)
        |> Util.String.crazyEncode
