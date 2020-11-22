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
    , setValues
    , update
    , view
    )

import Api
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Comp.CustomFieldInput
import Comp.FixedDropdown
import Data.CustomFieldChange exposing (CustomFieldChange(..))
import Data.Flags exposing (Flags)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
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
    List.filter
        (\e -> not <| Dict.member e.name visible)
        all


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
    Api.getCustomFields flags "" CustomFieldResp


setValues : List ItemFieldValue -> Msg
setValues values =
    SetValues values


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
    , dropdown = Comp.FixedDropdown.init (List.map mkItem fields)
    }



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , subs : Sub Msg
    , result : CustomFieldChange
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
                    update (ApplyField field) model

                Nothing ->
                    UpdateResult model_ Cmd.none Sub.none NoFieldChange

        ApplyField f ->
            let
                ( fm, fc ) =
                    Comp.CustomFieldInput.init f

                visible =
                    Dict.insert f.name (VisibleField f fm) model.visibleFields

                fSelect =
                    mkFieldSelect (currentOptions model.allFields visible)

                -- have to re-state the open menu when this is invoked
                -- from a click in the dropdown
                fSelectDropdown =
                    fSelect.dropdown

                dropdownOpen =
                    { fSelectDropdown | menuOpen = True }

                model_ =
                    { model
                        | fieldSelect = { fSelect | dropdown = dropdownOpen }
                        , visibleFields = visible
                    }

                cmd_ =
                    Cmd.map (CustomFieldInputMsg f) fc
            in
            UpdateResult model_ cmd_ Sub.none NoFieldChange

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
                            Comp.CustomFieldInput.update lm inputModel

                        model_ =
                            { model
                                | visibleFields =
                                    Dict.insert field.name (VisibleField field res.model) model.visibleFields
                            }

                        cmd_ =
                            Cmd.map (CustomFieldInputMsg field) res.cmd

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
                        update (RemoveField field) model_

                    else
                        UpdateResult model_ cmd_ Sub.none result

                Nothing ->
                    UpdateResult model Cmd.none Sub.none NoFieldChange

        SetValues values ->
            let
                field value =
                    CustomField value.id value.name value.label value.ftype 0 0

                merge fv ( dict, cmds ) =
                    let
                        ( fim, fic ) =
                            Comp.CustomFieldInput.initWith fv

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



--- View


type alias ViewSettings =
    { showAddButton : Bool
    , classes : String
    , fieldIcon : CustomField -> Maybe String
    }


view : ViewSettings -> Model -> Html Msg
view viewSettings model =
    div [ class viewSettings.classes ]
        (viewMenuBar viewSettings model
            :: List.map (viewCustomField viewSettings model) (visibleFields model)
        )


viewMenuBar : ViewSettings -> Model -> Html Msg
viewMenuBar viewSettings model =
    let
        { dropdown, selected } =
            model.fieldSelect
    in
    div
        [ classList
            [ ( "field", True )
            , ( "ui action input", viewSettings.showAddButton )
            ]
        ]
        (Html.map FieldSelectMsg
            (Comp.FixedDropdown.viewStyled "fluid" (Maybe.map mkItem selected) dropdown)
            :: (if viewSettings.showAddButton then
                    [ addFieldLink "" model
                    ]

                else
                    []
               )
        )


viewCustomField : ViewSettings -> Model -> CustomField -> Html Msg
viewCustomField viewSettings model field =
    let
        visibleField =
            Dict.get field.name model.visibleFields
    in
    case visibleField of
        Just vf ->
            Html.map (CustomFieldInputMsg field)
                (Comp.CustomFieldInput.view "field"
                    (viewSettings.fieldIcon vf.field)
                    vf.inputModel
                )

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
