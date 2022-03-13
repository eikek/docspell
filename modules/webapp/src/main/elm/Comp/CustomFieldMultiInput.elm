{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.CustomFieldMultiInput exposing
    ( Model
    , Msg
    , UpdateResult
    , ViewSettings
    , init
    , initCmd
    , initWith
    , isEmpty
    , nonEmpty
    , reset
    , setOptions
    , setValues
    , update
    , updateSearch
    , view2
    )

import Api
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Comp.CustomFieldInput
import Comp.FixedDropdown
import Comp.SimpleTextInput
import Data.CustomFieldChange exposing (CustomFieldChange(..))
import Data.CustomFieldOrder
import Data.CustomFieldType
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.CustomFieldMultiInput exposing (Texts)
import Styles as S
import Util.CustomField
import Util.Maybe


type alias Model =
    { fieldSelect : FieldSelect
    , visibleFields : Dict String VisibleField
    , allFields : List CustomField
    }


type alias FieldSelect =
    { selected : Maybe CustomField
    , dropdown : Comp.FixedDropdown.Model CustomField
    }


type alias VisibleField =
    { field : CustomField
    , inputModel : Comp.CustomFieldInput.Model
    }


visibleFields : Model -> List CustomField
visibleFields model =
    let
        labelThenName cv =
            Maybe.withDefault cv.name cv.label
    in
    Dict.toList model.visibleFields
        |> List.map (Tuple.second >> .field)
        |> List.sortBy labelThenName


currentOptions : List CustomField -> Dict String VisibleField -> List CustomField
currentOptions all visible =
    List.sortBy Util.CustomField.nameOrLabel all
        |> List.filter (\e -> not <| Dict.member e.name visible)


type Msg
    = CustomFieldInputMsg CustomField Comp.CustomFieldInput.Msg
    | ApplyField CustomField
    | RemoveField CustomField
    | CreateNewField
    | CustomFieldResp (Result Http.Error CustomFieldList)
    | FieldSelectMsg (Comp.FixedDropdown.Msg CustomField)
    | SetValues (List ItemFieldValue)


nonEmpty : Model -> Bool
nonEmpty model =
    not (isEmpty model)


isEmpty : Model -> Bool
isEmpty model =
    List.isEmpty model.allFields


initWith : List CustomField -> Model
initWith fields =
    { fieldSelect = mkFieldSelect (currentOptions fields Dict.empty)
    , visibleFields = Dict.empty
    , allFields = fields
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initWith []
    , initCmd flags
    )


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getCustomFields flags "" Data.CustomFieldOrder.LabelAsc CustomFieldResp


setValues : List ItemFieldValue -> Msg
setValues values =
    SetValues values


setOptions : List CustomField -> Msg
setOptions fields =
    CustomFieldResp (Ok (CustomFieldList fields))


reset : Model -> Model
reset model =
    let
        opts =
            currentOptions model.allFields Dict.empty
    in
    { model
        | fieldSelect = mkFieldSelect opts
        , visibleFields = Dict.empty
    }


mkFieldSelect : List CustomField -> FieldSelect
mkFieldSelect fields =
    { selected = Nothing
    , dropdown = Comp.FixedDropdown.init fields
    }



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , result : CustomFieldChange
    }


update : Flags -> Msg -> Model -> UpdateResult
update =
    update1 False


updateSearch : Flags -> Msg -> Model -> UpdateResult
updateSearch =
    update1 True


update1 : Bool -> Flags -> Msg -> Model -> UpdateResult
update1 forSearch flags msg model =
    case msg of
        CreateNewField ->
            UpdateResult model Cmd.none Sub.none FieldCreateNew

        CustomFieldResp (Ok list) ->
            let
                model_ =
                    { model
                        | allFields = list.items
                        , fieldSelect = mkFieldSelect (currentOptions list.items model.visibleFields)
                    }
            in
            UpdateResult model_ Cmd.none Sub.none NoFieldChange

        CustomFieldResp (Err _) ->
            UpdateResult model Cmd.none Sub.none NoFieldChange

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
                    update1 forSearch flags (ApplyField field) model

                Nothing ->
                    UpdateResult model_ Cmd.none Sub.none NoFieldChange

        ApplyField f ->
            let
                ( fm, fc ) =
                    Comp.CustomFieldInput.init1 (textInputCfg forSearch) f

                visible =
                    Dict.insert f.name (VisibleField f fm) model.visibleFields

                fSelect =
                    mkFieldSelect (currentOptions model.allFields visible)

                model_ =
                    { model
                        | fieldSelect = fSelect
                        , visibleFields = visible
                    }

                cmd_ =
                    Cmd.map (CustomFieldInputMsg f) fc

                change =
                    case Data.CustomFieldType.fromString f.ftype of
                        Just Data.CustomFieldType.Boolean ->
                            FieldValueChange f (Util.CustomField.boolValue False)

                        _ ->
                            NoFieldChange
            in
            UpdateResult model_ cmd_ Sub.none change

        RemoveField f ->
            let
                visible =
                    Dict.remove f.name model.visibleFields

                model_ =
                    { model
                        | visibleFields = visible
                        , fieldSelect = mkFieldSelect (currentOptions model.allFields visible)
                    }
            in
            UpdateResult model_ Cmd.none Sub.none (FieldValueRemove f)

        CustomFieldInputMsg f lm ->
            let
                visibleField =
                    Dict.get f.name model.visibleFields
            in
            case visibleField of
                Just { field, inputModel } ->
                    let
                        res =
                            if forSearch then
                                Comp.CustomFieldInput.updateSearch lm inputModel

                            else
                                Comp.CustomFieldInput.update lm inputModel

                        model_ =
                            { model
                                | visibleFields =
                                    Dict.insert field.name (VisibleField field res.model) model.visibleFields
                            }

                        cmd_ =
                            Cmd.map (CustomFieldInputMsg field) res.cmd

                        sub_ =
                            Sub.map (CustomFieldInputMsg field) res.sub

                        result =
                            case res.result of
                                Comp.CustomFieldInput.Value str ->
                                    FieldValueChange field str

                                Comp.CustomFieldInput.RemoveField ->
                                    FieldValueRemove field

                                Comp.CustomFieldInput.NoResult ->
                                    NoFieldChange
                    in
                    if res.result == Comp.CustomFieldInput.RemoveField then
                        update1 forSearch flags (RemoveField field) model_

                    else
                        UpdateResult model_ cmd_ sub_ result

                Nothing ->
                    UpdateResult model Cmd.none Sub.none NoFieldChange

        SetValues values ->
            let
                field value =
                    CustomField value.id value.name value.label value.ftype 0 0

                merge fv ( dict, cmds ) =
                    let
                        ( fim, fic ) =
                            Comp.CustomFieldInput.initWith1 (textInputCfg forSearch) fv

                        f =
                            field fv
                    in
                    ( Dict.insert fv.name (VisibleField f fim) dict
                    , Cmd.map (CustomFieldInputMsg f) fic :: cmds
                    )

                ( modelDict, cmdList ) =
                    List.foldl merge ( Dict.empty, [] ) values

                model_ =
                    { model
                        | fieldSelect = mkFieldSelect (currentOptions model.allFields modelDict)
                        , visibleFields = modelDict
                    }
            in
            UpdateResult model_ (Cmd.batch cmdList) Sub.none NoFieldChange


textInputCfg : Bool -> Comp.SimpleTextInput.Config
textInputCfg forSearch =
    if forSearch then
        Comp.SimpleTextInput.onEnterOnly

    else
        Comp.SimpleTextInput.defaultConfig



--- View2


type alias ViewSettings =
    { showAddButton : Bool
    , classes : String
    , fieldIcon : CustomField -> Maybe String
    , style : DS.DropdownStyle
    , createCustomFieldTitle : String
    , selectPlaceholder : String
    }


view2 : Texts -> ViewSettings -> Model -> Html Msg
view2 texts viewSettings model =
    div [ class viewSettings.classes ]
        (viewMenuBar2 viewSettings model
            :: List.map (viewCustomField2 texts viewSettings model) (visibleFields model)
        )


viewMenuBar2 : ViewSettings -> Model -> Html Msg
viewMenuBar2 viewSettings model =
    let
        { dropdown, selected } =
            model.fieldSelect

        ddstyle =
            viewSettings.style

        ddstyleFlex =
            { display = \f -> Maybe.withDefault f.name f.label
            , icon = \_ -> Nothing
            , style = { ddstyle | root = ddstyle.root ++ " flex-grow" }
            , selectPlaceholder = viewSettings.selectPlaceholder
            }
    in
    div
        [ classList
            [ ( "", viewSettings.showAddButton )
            ]
        , class " flex flex-row"
        ]
        (Html.map FieldSelectMsg
            (Comp.FixedDropdown.viewStyled2
                ddstyleFlex
                False
                selected
                dropdown
            )
            :: (if viewSettings.showAddButton then
                    [ addFieldLink viewSettings.createCustomFieldTitle "ml-1" model
                    ]

                else
                    []
               )
        )


viewCustomField2 : Texts -> ViewSettings -> Model -> CustomField -> Html Msg
viewCustomField2 texts viewSettings model field =
    let
        visibleField =
            Dict.get field.name model.visibleFields
    in
    case visibleField of
        Just vf ->
            Html.map (CustomFieldInputMsg field)
                (Comp.CustomFieldInput.view2 texts.customFieldInput
                    "mt-2"
                    (viewSettings.fieldIcon vf.field)
                    vf.inputModel
                )

        Nothing ->
            span [] []


addFieldLink : String -> String -> Model -> Html Msg
addFieldLink titleStr classes _ =
    a
        [ class classes
        , class S.secondaryButton

        --        , class "absolute -right-12 top-0"
        , href "#"
        , onClick CreateNewField
        , title titleStr
        ]
        [ i [ class "fa fa-plus" ] []
        ]
