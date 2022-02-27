{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.EquipmentManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Equipment
import Api.Model.EquipmentList exposing (EquipmentList)
import Comp.Basic as B
import Comp.EquipmentForm
import Comp.EquipmentTable
import Comp.MenuBar as MB
import Comp.YesNoDimmer
import Data.EquipmentOrder exposing (EquipmentOrder)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onSubmit)
import Http
import Messages.Comp.EquipmentManage exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { tableModel : Comp.EquipmentTable.Model
    , formModel : Comp.EquipmentForm.Model
    , viewMode : ViewMode
    , formError : FormError
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , query : String
    , order : EquipmentOrder
    }


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorSubmit String
    | FormErrorInvalid


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tableModel = Comp.EquipmentTable.emptyModel
    , formModel = Comp.EquipmentForm.emptyModel
    , viewMode = Table
    , formError = FormErrorNone
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , query = ""
    , order = Data.EquipmentOrder.NameAsc
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel, Api.getEquipments flags emptyModel.query emptyModel.order EquipmentResp )


type Msg
    = TableMsg Comp.EquipmentTable.Msg
    | FormMsg Comp.EquipmentForm.Msg
    | LoadEquipments
    | EquipmentResp (Result Http.Error EquipmentList)
    | SetViewMode ViewMode
    | InitNewEquipment
    | Submit
    | SubmitResp (Result Http.Error BasicResult)
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SetQuery String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg m ->
            let
                ( tm, tc, maybeOrder ) =
                    Comp.EquipmentTable.update flags m model.tableModel

                newOrder =
                    Maybe.withDefault model.order maybeOrder

                ( m2, c2 ) =
                    ( { model
                        | tableModel = tm
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if Util.Maybe.nonEmpty tm.selected then
                                FormErrorNone

                            else
                                model.formError
                        , order = newOrder
                      }
                    , Cmd.map TableMsg tc
                    )

                ( m3, c3 ) =
                    case tm.selected of
                        Just equipment ->
                            update flags (FormMsg (Comp.EquipmentForm.SetEquipment equipment)) m2

                        Nothing ->
                            ( m2, Cmd.none )

                ( m4, c4 ) =
                    if model.order == newOrder then
                        ( m3, Cmd.none )

                    else
                        update flags LoadEquipments m3
            in
            ( m4, Cmd.batch [ c2, c3, c4 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EquipmentForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadEquipments ->
            ( { model | loading = True }, Api.getEquipments flags model.query model.order EquipmentResp )

        EquipmentResp (Ok equipments) ->
            let
                m2 =
                    { model | viewMode = Table, loading = False }
            in
            update flags (TableMsg (Comp.EquipmentTable.SetEquipments equipments.items)) m2

        EquipmentResp (Err _) ->
            ( { model | loading = False }, Cmd.none )

        SetViewMode m ->
            let
                m2 =
                    { model | viewMode = m }
            in
            case m of
                Table ->
                    update flags (TableMsg Comp.EquipmentTable.Deselect) m2

                Form ->
                    ( m2, Cmd.none )

        InitNewEquipment ->
            let
                nm =
                    { model | viewMode = Form, formError = FormErrorNone }

                equipment =
                    Api.Model.Equipment.empty
            in
            update flags (FormMsg (Comp.EquipmentForm.SetEquipment equipment)) nm

        Submit ->
            let
                equipment =
                    Comp.EquipmentForm.getEquipment model.formModel

                valid =
                    Comp.EquipmentForm.isValid model.formModel
            in
            if valid then
                ( { model | loading = True }, Api.postEquipment flags equipment SubmitResp )

            else
                ( { model | formError = FormErrorInvalid }, Cmd.none )

        SubmitResp (Ok res) ->
            if res.success then
                let
                    ( m2, c2 ) =
                        update flags (SetViewMode Table) model

                    ( m3, c3 ) =
                        update flags LoadEquipments m2
                in
                ( { m3 | loading = False }, Cmd.batch [ c2, c3 ] )

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none )

        RequestDelete ->
            update flags (YesNoMsg Comp.YesNoDimmer.activate) model

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                equip =
                    Comp.EquipmentForm.getEquipment model.formModel

                cmd =
                    if confirmed then
                        Api.deleteEquip flags equip.id SubmitResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )

        SetQuery str ->
            let
                m =
                    { model | query = str }
            in
            ( m, Api.getEquipments flags str model.order EquipmentResp )



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    if model.viewMode == Table then
        viewTable2 texts model

    else
        viewForm2 texts model


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = texts.basics.searchPlaceholder
                    , icon = Just "fa fa-search"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewEquipment
                    , title = texts.createNewEquipment
                    , icon = Just "fa fa-plus"
                    , label = texts.newEquipment
                    }
                ]
            , rootClasses = "mb-4"
            , sticky = True
            }
        , Html.map TableMsg
            (Comp.EquipmentTable.view2 texts.equipmentTable
                model.order
                model.tableModel
            )
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewForm2 : Texts -> Model -> Html Msg
viewForm2 texts model =
    let
        newEquipment =
            model.formModel.equipment.id == ""

        dimmerSettings2 =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteEquipment
                texts.basics.yes
                texts.basics.no
    in
    Html.form
        [ class "relative flex flex-col"
        , onSubmit Submit
        ]
        [ Html.map YesNoMsg
            (Comp.YesNoDimmer.viewN
                True
                dimmerSettings2
                model.deleteConfirm
            )
        , if newEquipment then
            h1 [ class S.header2 ]
                [ text texts.createNewEquipment
                ]

          else
            h1 [ class S.header2 ]
                [ text model.formModel.equipment.name
                , div [ class "opacity-50 text-sm" ]
                    [ text (texts.basics.id ++ ": ")
                    , text model.formModel.equipment.id
                    ]
                ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = SetViewMode Table
                    , title = texts.basics.backToList
                    , icon = Just "fa fa-arrow-left"
                    , label = texts.basics.cancel
                    }
                ]
            , end =
                if not newEquipment then
                    [ MB.DeleteButton
                        { tagger = RequestDelete
                        , title = texts.deleteThisEquipment
                        , icon = Just "fa fa-trash"
                        , label = texts.basics.delete
                        }
                    ]

                else
                    []
            , rootClasses = "mb-4"
            , sticky = True
            }
        , div
            [ classList
                [ ( "hidden", model.formError == FormErrorNone )
                ]
            , class S.errorMessage
            , class "my-2"
            ]
            [ case model.formError of
                FormErrorNone ->
                    text ""

                FormErrorSubmit m ->
                    text m

                FormErrorInvalid ->
                    text texts.correctFormErrors

                FormErrorHttp err ->
                    text (texts.httpError err)
            ]
        , Html.map FormMsg (Comp.EquipmentForm.view2 texts.equipmentForm model.formModel)
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]
