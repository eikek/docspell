module Comp.CustomFieldMultiInput exposing
    ( FieldResult(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , initCmd
    , initWith
    , update
    , view
    )

import Api
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Comp.CustomFieldInput
import Comp.FixedDropdown
import Data.Flags exposing (Flags)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Util.Maybe


type alias Model =
    { fieldModels : Dict String Comp.CustomFieldInput.Model
    , fieldSelect : FieldSelect
    , visibleFields : List CustomField
    , availableFields : List CustomField
    }


type Msg
    = CustomFieldInputMsg CustomField Comp.CustomFieldInput.Msg
    | ApplyField CustomField
    | RemoveField CustomField
    | CreateNewField
    | CustomFieldResp (Result Http.Error CustomFieldList)
    | FieldSelectMsg (Comp.FixedDropdown.Msg CustomField)


type FieldResult
    = NoResult
    | FieldValueRemove CustomField
    | FieldValueChange CustomField String
    | FieldCreateNew


type alias FieldSelect =
    { selected : Maybe CustomField
    , dropdown : Comp.FixedDropdown.Model CustomField
    }


initWith : List CustomField -> Model
initWith fields =
    { fieldModels = Dict.empty
    , fieldSelect = mkFieldSelect fields
    , visibleFields = []
    , availableFields = fields
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initWith []
    , initCmd flags
    )


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getCustomFields flags "" CustomFieldResp


mkFieldSelect : List CustomField -> FieldSelect
mkFieldSelect fields =
    { selected = Nothing
    , dropdown = Comp.FixedDropdown.init (List.map mkItem fields)
    }



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , subs : Sub Msg
    , result : FieldResult
    }


mkItem : CustomField -> Comp.FixedDropdown.Item CustomField
mkItem f =
    Comp.FixedDropdown.Item f (Maybe.withDefault f.name f.label)


update : Msg -> Model -> UpdateResult
update msg model =
    case msg of
        CreateNewField ->
            UpdateResult model Cmd.none Sub.none FieldCreateNew

        CustomFieldResp (Ok list) ->
            let
                model_ =
                    { model
                        | availableFields = list.items
                        , fieldSelect = mkFieldSelect list.items
                    }
            in
            UpdateResult model_ Cmd.none Sub.none NoResult

        CustomFieldResp (Err _) ->
            UpdateResult model Cmd.none Sub.none NoResult

        FieldSelectMsg lm ->
            let
                ( dm_, sel ) =
                    Comp.FixedDropdown.update lm model.fieldSelect.dropdown

                newF =
                    Util.Maybe.or [ sel, model.fieldSelect.selected ]

                model_ =
                    { model
                        | fieldSelect =
                            { selected = newF
                            , dropdown = dm_
                            }
                    }
            in
            case sel of
                Just field ->
                    update (ApplyField field) model

                Nothing ->
                    UpdateResult model_ Cmd.none Sub.none NoResult

        ApplyField f ->
            let
                notSelected e =
                    e /= f

                ( fm, fc ) =
                    Comp.CustomFieldInput.init f

                avail =
                    List.filter notSelected model.availableFields

                visible =
                    f :: model.visibleFields

                fSelect =
                    mkFieldSelect avail

                -- have to re-state the open menu when this is invoked
                -- from a click in the dropdown
                fSelectDropdown =
                    fSelect.dropdown

                dropdownOpen =
                    { fSelectDropdown | menuOpen = True }

                model_ =
                    { model
                        | fieldSelect = { fSelect | dropdown = dropdownOpen }
                        , availableFields = avail
                        , visibleFields = visible
                        , fieldModels = Dict.insert f.name fm model.fieldModels
                    }

                cmd_ =
                    Cmd.map (CustomFieldInputMsg f) fc
            in
            UpdateResult model_ cmd_ Sub.none NoResult

        RemoveField f ->
            let
                avail =
                    f :: model.availableFields

                visible =
                    List.filter (\e -> e /= f) model.visibleFields

                model_ =
                    { model
                        | availableFields = avail
                        , visibleFields = visible
                        , fieldSelect = mkFieldSelect avail
                    }
            in
            UpdateResult model_ Cmd.none Sub.none (FieldValueRemove f)

        CustomFieldInputMsg field lm ->
            let
                fieldModel =
                    Dict.get field.name model.fieldModels
            in
            case fieldModel of
                Just fm ->
                    let
                        res =
                            Comp.CustomFieldInput.update lm fm

                        model_ =
                            { model | fieldModels = Dict.insert field.name res.model model.fieldModels }

                        cmd_ =
                            Cmd.map (CustomFieldInputMsg field) res.cmd

                        result =
                            case res.result of
                                Comp.CustomFieldInput.Value str ->
                                    FieldValueChange field str

                                Comp.CustomFieldInput.RemoveField ->
                                    FieldValueRemove field

                                Comp.CustomFieldInput.NoResult ->
                                    NoResult
                    in
                    if res.result == Comp.CustomFieldInput.RemoveField then
                        update (RemoveField field) model_

                    else
                        UpdateResult model_ cmd_ Sub.none result

                Nothing ->
                    UpdateResult model Cmd.none Sub.none NoResult


view : String -> Model -> Html Msg
view classes model =
    div [ class classes ]
        (viewMenuBar model
            :: List.map (viewCustomField model) model.visibleFields
        )


viewMenuBar : Model -> Html Msg
viewMenuBar model =
    let
        { dropdown, selected } =
            model.fieldSelect
    in
    div [ class "ui action input field" ]
        [ Html.map FieldSelectMsg
            (Comp.FixedDropdown.viewStyled "fluid" (Maybe.map mkItem selected) dropdown)
        , addFieldLink "" model
        ]


viewCustomField : Model -> CustomField -> Html Msg
viewCustomField model field =
    let
        fieldModel =
            Dict.get field.name model.fieldModels
    in
    case fieldModel of
        Just fm ->
            Html.map (CustomFieldInputMsg field)
                (Comp.CustomFieldInput.view "field" Nothing fm)

        Nothing ->
            span [] []


addFieldLink : String -> Model -> Html Msg
addFieldLink classes _ =
    a
        [ class ("ui icon button " ++ classes)
        , href "#"
        , onClick CreateNewField
        , title "Create a new custom field"
        ]
        [ i [ class "plus link icon" ] []
        ]
