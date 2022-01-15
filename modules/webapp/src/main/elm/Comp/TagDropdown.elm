{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


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
import Html exposing (Html, a, div, i)
import Html.Attributes exposing (class, classList, href, title)
import Html.Events exposing (onClick)
import Messages.Comp.TagDropdown exposing (Texts)
import Util.List


type alias Model =
    { ddm : Comp.Dropdown.Model Tag
    , allTags : List Tag
    , constrainedCat : Maybe String
    }


type Msg
    = DropdownMsg (Comp.Dropdown.Msg Tag)
    | GetTagsResp TagList
    | ConstrainCat String


emptyModel : Model
emptyModel =
    { ddm = makeDropdownModel
    , allTags = []
    , constrainedCat = Nothing
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
    GetTagsResp (TagList 0 tags)


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


isConstrained : Model -> String -> Bool
isConstrained model category =
    model.constrainedCat == Just category



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
            ( { model
                | ddm = dm
                , constrainedCat =
                    if isChangeMsg msg then
                        Nothing

                    else
                        model.constrainedCat
              }
            , Cmd.map DropdownMsg dc
            )

        GetTagsResp list ->
            let
                newModel =
                    { model | allTags = list.items }

                ddMsg =
                    Comp.Dropdown.SetOptions newModel.allTags
            in
            update (DropdownMsg ddMsg) newModel

        ConstrainCat cat ->
            let
                setOpts tags =
                    DropdownMsg (Comp.Dropdown.SetOptions tags)
            in
            if model.constrainedCat == Just cat then
                update (setOpts model.allTags)
                    { model | constrainedCat = Nothing }

            else
                update (setOpts <| List.filter (isCategory cat) model.allTags)
                    { model | constrainedCat = Just cat }


isCategory : String -> Tag -> Bool
isCategory cat tag =
    tag.category == Just cat || (tag.category == Nothing && cat == "")



--- view


view : Texts -> UiSettings -> DropdownStyle -> Model -> Html Msg
view texts settings dds model =
    let
        viewSettings =
            tagSettings texts.placeholder dds
    in
    div [ class "flex flex-col" ]
        [ viewCategorySelect texts settings model
        , Html.map DropdownMsg (Comp.Dropdown.view2 viewSettings settings model.ddm)
        ]


viewCategorySelect : Texts -> UiSettings -> Model -> Html Msg
viewCategorySelect texts settings model =
    let
        categories =
            List.map .category model.allTags
                |> List.map (Maybe.withDefault "")
                |> Util.List.distinct
                |> List.sort

        catFilterLink cat =
            a
                [ classList
                    [ ( "opacity-75", not (isConstrained model cat) )
                    ]
                , href "#"
                , title <|
                    if cat == "" then
                        texts.noCategory

                    else
                        cat
                , onClick (ConstrainCat cat)
                ]
                [ if cat == "" then
                    i
                        [ class <|
                            if isConstrained model cat then
                                "fa fa-check-circle font-thin"

                            else
                                "fa fa-circle font-thin"
                        ]
                        []

                  else
                    i
                        [ classList
                            [ ( "fa fa-circle", not (isConstrained model cat) )
                            , ( "fa fa-check-circle", isConstrained model cat )
                            ]
                        , class <| Data.UiSettings.catColorFg2 settings cat
                        ]
                        []
                ]
    in
    div
        [ class "flex-wrap space-x-1 text-xl sm:text-sm "
        , classList [ ( "hidden", not model.ddm.menuOpen ) ]
        ]
        (List.map catFilterLink categories)



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
