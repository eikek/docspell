{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.Person exposing (mkPersonOption)

import Api.Model.IdName exposing (IdName)
import Api.Model.Person exposing (Person)
import Comp.Dropdown
import Dict exposing (Dict)
import Util.String


mkPersonOption : IdName -> Dict String Person -> Comp.Dropdown.Option
mkPersonOption idref personDict =
    let
        org =
            Dict.get idref.id personDict
                |> Maybe.andThen .organization
                |> Maybe.map .name
                |> Maybe.map (Util.String.ellipsis 15)
                |> Maybe.withDefault ""
    in
    Comp.Dropdown.Option idref.name org
