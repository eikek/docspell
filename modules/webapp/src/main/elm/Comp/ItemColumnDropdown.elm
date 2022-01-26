{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemColumnDropdown exposing (Model, Msg, getSelected, init, update, view)

import Comp.Dropdown exposing (Option)
import Data.DropdownStyle
import Data.ItemColumn exposing (ItemColumn(..))
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html)
import Messages.Comp.ItemColumnDropdown exposing (Texts)


type Model
    = Model (Comp.Dropdown.Model ItemColumn)


type Msg
    = DropdownMsg (Comp.Dropdown.Msg ItemColumn)


init : List ItemColumn -> Model
init selected =
    Model <|
        Comp.Dropdown.makeMultipleList
            { options = Data.ItemColumn.all, selected = selected }


getSelected : Model -> List ItemColumn
getSelected (Model dm) =
    Comp.Dropdown.getSelected dm



--- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        dmodel =
            case model of
                Model a ->
                    a
    in
    case msg of
        DropdownMsg lm ->
            let
                ( dm, dc ) =
                    Comp.Dropdown.update lm dmodel
            in
            ( Model dm, Cmd.map DropdownMsg dc )



--- View


itemOption : Texts -> ItemColumn -> Option
itemOption texts item =
    { text = texts.column.label item
    , additional = ""
    }


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        viewSettings =
            { makeOption = itemOption texts
            , placeholder = texts.placeholder
            , labelColor = \_ -> \_ -> ""
            , style = Data.DropdownStyle.mainStyle
            }

        dm =
            case model of
                Model a ->
                    a
    in
    Html.map DropdownMsg
        (Comp.Dropdown.view2 viewSettings settings dm)
