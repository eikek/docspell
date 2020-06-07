module Util.Tag exposing (makeDropdownModel)

import Api.Model.Tag exposing (Tag)
import Comp.Dropdown
import Data.UiSettings


makeDropdownModel : Comp.Dropdown.Model Tag
makeDropdownModel =
    Comp.Dropdown.makeModel
        { multiple = True
        , searchable = \n -> n > 4
        , makeOption = \tag -> { value = tag.id, text = tag.name }
        , labelColor =
            \tag ->
                \settings ->
                    "basic " ++ Data.UiSettings.tagColorString tag settings
        , placeholder = "Choose a tag…"
        }
