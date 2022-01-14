{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.Tag exposing
    ( catSettings
    , getCategories
    , makeCatDropdownModel
    , makeDropdownModel
    , tagSettings
    )

import Api.Model.Tag exposing (Tag)
import Comp.Dropdown
import Data.DropdownStyle as DS
import Data.UiSettings
import Util.List


makeDropdownModel : Comp.Dropdown.Model Tag
makeDropdownModel =
    let
        init =
            Comp.Dropdown.makeModel
                { multiple = True
                , searchable = \n -> n > 0
                }
    in
    { init | searchWithAdditional = True }


tagSettings : String -> DS.DropdownStyle -> Comp.Dropdown.ViewSettings Tag
tagSettings placeholder ds =
    { makeOption = \tag -> { text = tag.name, additional = Maybe.withDefault "" tag.category }
    , labelColor =
        \tag ->
            \settings ->
                Data.UiSettings.tagColorString2 tag settings
    , placeholder = placeholder
    , style = ds
    }


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
