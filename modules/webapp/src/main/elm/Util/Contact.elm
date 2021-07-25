{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Util.Contact exposing (toString)

import Api.Model.Contact exposing (Contact)


toString : List Contact -> String
toString contacts =
    List.map (\c -> c.kind ++ ": " ++ c.value) contacts
        |> List.intersperse ", "
        |> String.concat
