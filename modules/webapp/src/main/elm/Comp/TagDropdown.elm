module Comp.TagDropdown exposing
    ( Model
    , Msg
    , emptyModel
    , getSelected
    , init
    , initSelected
    , initWith
    , isChangeMsg
    , setSelected
    , update
    , view
    )

import Api
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.Dropdown
import Data.DropdownStyle exposing (DropdownStyle)
import Data.Flags exposing (Flags)
import Data.TagOrder
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html)
import Messages.Comp.TagDropdown exposing (Texts)


type alias Model =
    { ddm : Comp.Dropdown.Model Tag
    , allTags : List Tag
    }


type Msg
    = DropdownMsg (Comp.Dropdown.Msg Tag)
    | GetTagsResp TagList


emptyModel : Model
emptyModel =
    { ddm = makeDropdownModel
    , allTags = []
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, getOptions flags )


initSelected : Flags -> List Tag -> ( Model, Cmd Msg )
initSelected flags selected =
    ( update (setSelected selected) emptyModel
        |> Tuple.first
    , getOptions flags
    )


initWith : List Tag -> List Tag -> Model
initWith options selected =
    update (setSelected selected) emptyModel
        |> Tuple.first
        |> update (setOptions options)
        |> Tuple.first


getSelected : Model -> List Tag
getSelected model =
    Comp.Dropdown.getSelected model.ddm


setOptions : List Tag -> Msg
setOptions tags =
    DropdownMsg (Comp.Dropdown.SetOptions tags)


setSelected : List Tag -> Msg
setSelected tags =
    DropdownMsg (Comp.Dropdown.SetSelection tags)


isChangeMsg : Msg -> Bool
isChangeMsg msg =
    case msg of
        DropdownMsg m ->
            Comp.Dropdown.isDropdownChangeMsg m

        _ ->
            False



--- api


getOptions : Flags -> Cmd Msg
getOptions flags =
    Api.getTagsIgnoreError flags "" Data.TagOrder.NameAsc GetTagsResp



--- update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DropdownMsg lm ->
            let
                ( dm, dc ) =
                    Comp.Dropdown.update lm model.ddm
            in
            ( { model | ddm = dm }, Cmd.map DropdownMsg dc )

        GetTagsResp list ->
            let
                newModel =
                    { model | allTags = list.items }

                ddMsg =
                    Comp.Dropdown.SetOptions newModel.allTags
            in
            update (DropdownMsg ddMsg) newModel



--- view


view : Texts -> UiSettings -> DropdownStyle -> Model -> Html Msg
view texts settings dds model =
    let
        viewSettings =
            tagSettings texts.placeholder dds
    in
    Html.map DropdownMsg (Comp.Dropdown.view2 viewSettings settings model.ddm)



--- private helper


makeDropdownModel : Comp.Dropdown.Model Tag
makeDropdownModel =
    let
        m =
            Comp.Dropdown.makeModel
                { multiple = True
                , searchable = \n -> n > 0
                }
    in
    { m | searchWithAdditional = True }


tagSettings : String -> DropdownStyle -> Comp.Dropdown.ViewSettings Tag
tagSettings placeholder ds =
    { makeOption = \tag -> { text = tag.name, additional = Maybe.withDefault "" tag.category }
    , labelColor =
        \tag ->
            \settings ->
                Data.UiSettings.tagColorString2 tag settings
    , placeholder = placeholder
    , style = ds
    }
