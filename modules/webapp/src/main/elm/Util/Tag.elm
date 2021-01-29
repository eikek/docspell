module Util.Tag exposing
    ( getCategories
    , makeCatDropdownModel
    , makeDropdownModel
    , makeDropdownModel2
    )

import Api.Model.Tag exposing (Tag)
import Comp.Dropdown
import Data.UiSettings
import Util.List


makeDropdownModel : Comp.Dropdown.Model Tag
makeDropdownModel =
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 0
        , makeOption = \tag -> { value = tag.id, text = tag.name, additional = "" }
        , labelColor =
            \tag ->
                \settings ->
                    "basic " ++ Data.UiSettings.tagColorString tag settings
        , placeholder = "Choose a tag…"
        }


makeDropdownModel2 : Comp.Dropdown.Model Tag
makeDropdownModel2 =
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 0
        , makeOption = \tag -> { value = tag.id, text = tag.name, additional = "" }
        , labelColor =
            \tag ->
                \settings ->
                    Data.UiSettings.tagColorString2 tag settings
                        ++ -- legacy colors
                           " basic "
                        ++ Data.UiSettings.tagColorString tag settings
        , placeholder = "Choose a tag…"
        }


makeCatDropdownModel : Comp.Dropdown.Model String
makeCatDropdownModel =
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 0
        , makeOption = \cat -> { value = cat, text = cat, additional = "" }
        , labelColor = \_ -> \_ -> ""
        , placeholder = "Choose a tag category…"
        }


getCategories : List Tag -> List String
getCategories tags =
    List.filterMap .category tags
        |> Util.List.distinct
