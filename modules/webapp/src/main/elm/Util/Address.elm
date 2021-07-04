{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Util.Address exposing (toString)

import Api.Model.Address exposing (Address)


toString : Address -> String
toString a =
    [ a.street, a.zip, a.city, a.country ]
        |> List.filter (String.isEmpty >> not)
        |> List.intersperse ", "
        |> String.concat
