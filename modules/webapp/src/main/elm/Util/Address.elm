module Util.Address exposing (..)

import Api.Model.Address exposing (Address)

toString: Address -> String
toString a =
    [ a.street, a.zip, a.city, a.country ]
        |> List.filter (String.isEmpty >> not)
        |> List.intersperse ", "
        |> String.concat
