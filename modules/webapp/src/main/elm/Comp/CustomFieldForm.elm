{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.CustomFieldForm exposing
    ( Model
    , Msg
    , ViewSettings
    , init
    , initEmpty
    , makeField
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CustomField exposing (CustomField)
import Api.Model.NewCustomField exposing (NewCustomField)
import Comp.Basic as B
import Comp.FixedDropdown
import Comp.MenuBar as MB
import Comp.YesNoDimmer
import Data.CustomFieldType exposing (CustomFieldType)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Messages.Comp.CustomFieldForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { formState : FormState
    , field : CustomField
    , name : Maybe String
    , label : Maybe String
    , ftype : Maybe CustomFieldType
    , ftypeModel : Comp.FixedDropdown.Model CustomFieldType
    , loading : Bool
    , deleteDimmer : Comp.YesNoDimmer.Model
    }


type FormState
    = FormStateInitial
    | FormStateHttp Http.Error
    | FormStateNameRequired
    | FormStateTypeRequired
    | FormStateUpdateFailed UpdateType String
    | FormStateUpdateOk UpdateType


type UpdateType
    = UpdateCreate
    | UpdateChange
    | UpdateDelete


isFormError : FormState -> Bool
isFormError state =
    case state of
        FormStateInitial ->
            False

        FormStateHttp _ ->
            True

        FormStateNameRequired ->
            True

        FormStateTypeRequired ->
            True

        FormStateUpdateFailed _ _ ->
            True

        FormStateUpdateOk _ ->
            False


isFormSuccess : FormState -> Bool
isFormSuccess state =
    case state of
        FormStateInitial ->
            False

        _ ->
            not (isFormError state)


type Msg
    = SetName String
    | SetLabel String
    | FTypeMsg (Comp.FixedDropdown.Msg CustomFieldType)
    | RequestDelete
    | DeleteMsg Comp.YesNoDimmer.Msg
    | UpdateResp UpdateType (Result Http.Error BasicResult)
    | GoBack
    | SubmitForm


init : CustomField -> Model
init field =
    { formState = FormStateInitial
    , field = field
    , name = Util.Maybe.fromString field.name
    , label = field.label
    , ftype = Data.CustomFieldType.fromString field.ftype
    , ftypeModel =
        Comp.FixedDropdown.init Data.CustomFieldType.all
    , loading = False
    , deleteDimmer = Comp.YesNoDimmer.emptyModel
    }


initEmpty : Model
initEmpty =
    init Api.Model.CustomField.empty



--- Update


makeField : Model -> Result FormState NewCustomField
makeField model =
    let
        name =
            Maybe.map Ok model.name
                |> Maybe.withDefault (Err FormStateNameRequired)

        ftype =
            Maybe.map Data.CustomFieldType.asString model.ftype
                |> Maybe.map Ok
                |> Maybe.withDefault (Err FormStateTypeRequired)

        make n ft =
            NewCustomField n model.label ft
    in
    Result.map2 make name ftype


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Bool )
update flags msg model =
    case msg of
        GoBack ->
            ( model, Cmd.none, True )

        FTypeMsg lm ->
            let
                ( m2, sel ) =
                    Comp.FixedDropdown.update lm model.ftypeModel
            in
            ( { model | ftype = Util.Maybe.or [ sel, model.ftype ], ftypeModel = m2 }
            , Cmd.none
            , False
            )

        SetName str ->
            ( { model | name = Util.Maybe.fromString str }
            , Cmd.none
            , False
            )

        SetLabel str ->
            ( { model | label = Util.Maybe.fromString str }
            , Cmd.none
            , False
            )

        SubmitForm ->
            let
                newField =
                    makeField model
            in
            case newField of
                Ok f ->
                    ( model
                    , if model.field.id == "" then
                        Api.postCustomField flags f (UpdateResp UpdateCreate)

                      else
                        Api.putCustomField flags model.field.id f (UpdateResp UpdateChange)
                    , False
                    )

                Err fe ->
                    ( { model | formState = fe }
                    , Cmd.none
                    , False
                    )

        RequestDelete ->
            let
                ( dm, _ ) =
                    Comp.YesNoDimmer.update Comp.YesNoDimmer.activate model.deleteDimmer
            in
            ( { model | deleteDimmer = dm }, Cmd.none, False )

        DeleteMsg lm ->
            let
                ( dm, flag ) =
                    Comp.YesNoDimmer.update lm model.deleteDimmer

                cmd =
                    if flag then
                        Api.deleteCustomField flags model.field.id (UpdateResp UpdateDelete)

                    else
                        Cmd.none
            in
            ( { model | deleteDimmer = dm }, cmd, False )

        UpdateResp updateType (Ok r) ->
            ( { model
                | formState =
                    if r.success then
                        FormStateUpdateOk updateType

                    else
                        FormStateUpdateFailed updateType r.message
              }
            , Cmd.none
            , r.success
            )

        UpdateResp _ (Err err) ->
            ( { model | formState = FormStateHttp err }
            , Cmd.none
            , False
            )



--- View


type alias ViewSettings =
    { classes : String
    , showControls : Bool
    }



--- View2


view2 : Texts -> ViewSettings -> Model -> List (Html Msg)
view2 texts viewSettings model =
    let
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteField
                texts.basics.yes
                texts.basics.no

        ftypeCfg =
            { display = texts.fieldTypeLabel
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            , selectPlaceholder = texts.basics.selectPlaceholder
            }
    in
    (if viewSettings.showControls then
        [ viewButtons2 texts model ]

     else
        []
    )
        ++ [ div
                [ class viewSettings.classes
                , class "flex flex-col md:relative"
                ]
                [ Html.map DeleteMsg
                    (Comp.YesNoDimmer.viewN
                        True
                        dimmerSettings
                        model.deleteDimmer
                    )
                , div
                    [ classList
                        [ ( "hidden", model.formState == FormStateInitial )
                        , ( S.errorMessage, isFormError model.formState )
                        , ( S.successMessage, isFormSuccess model.formState )
                        ]
                    , class "my-2"
                    ]
                    [ case model.formState of
                        FormStateInitial ->
                            text ""

                        FormStateHttp err ->
                            text (texts.httpError err)

                        FormStateNameRequired ->
                            text texts.fieldNameRequired

                        FormStateTypeRequired ->
                            text texts.fieldTypeRequired

                        FormStateUpdateFailed _ m ->
                            text m

                        FormStateUpdateOk _ ->
                            text texts.updateSuccessful
                    ]
                , if model.field.id == "" then
                    div [ class "py-2 text-lg opacity-75" ]
                        [ text texts.createCustomField
                        ]

                  else
                    div [ class "py-2 text-lg opacity-75" ]
                        [ text texts.modifyTypeWarning
                        ]
                , div [ class "mb-4" ]
                    [ label
                        [ class S.inputLabel
                        , for "fieldname"
                        ]
                        [ text texts.basics.name
                        , B.inputRequired
                        ]
                    , input
                        [ type_ "text"
                        , onInput SetName
                        , model.name
                            |> Maybe.withDefault ""
                            |> value
                        , class S.textInput
                        , classList
                            [ ( S.inputErrorBorder, model.name == Nothing )
                            ]
                        , id "fieldname"
                        ]
                        []
                    , div [ class "opacity-75 text-sm" ]
                        [ text texts.nameInfo
                        ]
                    ]
                , div
                    [ class "mb-4"
                    ]
                    [ label [ class S.inputLabel ]
                        [ text texts.fieldFormat
                        , B.inputRequired
                        ]
                    , Html.map FTypeMsg
                        (Comp.FixedDropdown.viewStyled2
                            ftypeCfg
                            (model.ftype == Nothing)
                            model.ftype
                            model.ftypeModel
                        )
                    , div [ class "opacity-75 text-sm" ]
                        [ text texts.fieldFormatInfo
                        ]
                    ]
                , div [ class "mb-4" ]
                    [ label
                        [ class S.inputLabel
                        , for "fieldlabel"
                        ]
                        [ text texts.label ]
                    , input
                        [ type_ "text"
                        , onInput SetLabel
                        , model.label
                            |> Maybe.withDefault ""
                            |> value
                        , class S.textInput
                        , id "fieldlabel"
                        ]
                        []
                    , div [ class "opacity-75 text-sm" ]
                        [ text texts.labelInfo
                        ]
                    ]
                ]
           ]


viewButtons2 : Texts -> Model -> Html Msg
viewButtons2 texts model =
    MB.view
        { start =
            [ MB.PrimaryButton
                { tagger = SubmitForm
                , title = texts.basics.submitThisForm
                , icon = Just "fa fa-save"
                , label = texts.basics.submit
                }
            , MB.SecondaryButton
                { tagger = GoBack
                , title = texts.basics.backToList
                , icon = Just "fa fa-arrow-left"
                , label = texts.basics.cancel
                }
            ]
        , end =
            if model.field.id /= "" then
                [ MB.DeleteButton
                    { tagger = RequestDelete
                    , title = texts.deleteThisField
                    , icon = Just "fa fa-trash"
                    , label = texts.basics.delete
                    }
                ]

            else
                []
        , rootClasses = "mb-4"
        }
