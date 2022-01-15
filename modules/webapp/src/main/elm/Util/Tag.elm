{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.Tag exposing
    ( catSettings
    , getCategories
    , makeCatDropdownModel
    )

import Api.Model.Tag exposing (Tag)
import Comp.Dropdown
import Data.DropdownStyle as DS
import Util.List


makeCatDropdownModel : Comp.Dropdown.Model String
makeCatDropdownModel =
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 0
        }


catSettings : String -> DS.DropdownStyle -> Comp.Dropdown.ViewSettings String
catSettings placeholder ds =
    { makeOption = \cat -> { text = cat, additional = "" }
    , labelColor = \_ -> \_ -> ""
    , placeholder = placeholder
    , style = ds
    }


getCategories : List Tag -> List String
getCategories tags =
    List.filterMap .category tags
        |> Util.List.distinct
