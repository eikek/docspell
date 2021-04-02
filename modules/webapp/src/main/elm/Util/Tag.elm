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
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 0
        }


tagSettings : DS.DropdownStyle -> Comp.Dropdown.ViewSettings Tag
tagSettings ds =
    { makeOption = \tag -> { text = tag.name, additional = "" }
    , labelColor =
        \tag ->
            \settings ->
                Data.UiSettings.tagColorString2 tag settings
    , placeholder = "Choose a tag…"
    , style = ds
    }


makeCatDropdownModel : Comp.Dropdown.Model String
makeCatDropdownModel =
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 0
        }


catSettings : DS.DropdownStyle -> Comp.Dropdown.ViewSettings String
catSettings ds =
    { makeOption = \cat -> { text = cat, additional = "" }
    , labelColor = \_ -> \_ -> ""
    , placeholder = "Choose a tag category…"
    , style = ds
    }


getCategories : List Tag -> List String
getCategories tags =
    List.filterMap .category tags
        |> Util.List.distinct
