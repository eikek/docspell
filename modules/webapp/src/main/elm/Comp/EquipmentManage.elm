module Comp.EquipmentManage exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.Equipment
import Api.Model.EquipmentList exposing (EquipmentList)
import Comp.EquipmentForm
import Comp.EquipmentTable
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Util.Http
import Util.Maybe


type alias Model =
    { tableModel : Comp.EquipmentTable.Model
    , formModel : Comp.EquipmentForm.Model
    , viewMode : ViewMode
    , formError : Maybe String
    , loading : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , query : String
    }


type ViewMode
    = Table
    | Form


emptyModel : Model
emptyModel =
    { tableModel = Comp.EquipmentTable.emptyModel
    , formModel = Comp.EquipmentForm.emptyModel
    , viewMode = Table
    , formError = Nothing
    , loading = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , query = ""
    }


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
                ( tm, tc ) =
                    Comp.EquipmentTable.update flags m model.tableModel

                ( m2, c2 ) =
                    ( { model
                        | tableModel = tm
                        , viewMode = Maybe.map (\_ -> Form) tm.selected |> Maybe.withDefault Table
                        , formError =
                            if Util.Maybe.nonEmpty tm.selected then
                                Nothing

                            else
                                model.formError
                      }
                    , Cmd.map TableMsg tc
                    )

                ( m3, c3 ) =
                    case tm.selected of
                        Just equipment ->
                            update flags (FormMsg (Comp.EquipmentForm.SetEquipment equipment)) m2

                        Nothing ->
                            ( m2, Cmd.none )
            in
            ( m3, Cmd.batch [ c2, c3 ] )

        FormMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EquipmentForm.update flags m model.formModel
            in
            ( { model | formModel = m2 }, Cmd.map FormMsg c2 )

        LoadEquipments ->
            ( { model | loading = True }, Api.getEquipments flags "" EquipmentResp )

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
                    { model | viewMode = Form, formError = Nothing }

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
                ( { model | formError = Just "Please correct the errors in the form." }, Cmd.none )

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
                ( { model | formError = Just res.message, loading = False }, Cmd.none )

        SubmitResp (Err err) ->
            ( { model | formError = Just (Util.Http.errorToString err), loading = False }, Cmd.none )

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
            ( m, Api.getEquipments flags str EquipmentResp )


view : Model -> Html Msg
view model =
    if model.viewMode == Table then
        viewTable model

    else
        viewForm model


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ div [ class "ui secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , value model.query
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "item" ]
                    [ a
                        [ class "ui primary button"
                        , href "#"
                        , onClick InitNewEquipment
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Equipment"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.EquipmentTable.view model.tableModel)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]


viewForm : Model -> Html Msg
viewForm model =
    let
        newEquipment =
            model.formModel.equipment.id == ""
    in
    Html.form [ class "ui segment", onSubmit Submit ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
        , if newEquipment then
            h3 [ class "ui dividing header" ]
                [ text "Create new equipment"
                ]

          else
            h3 [ class "ui dividing header" ]
                [ text ("Edit equipment: " ++ model.formModel.equipment.name)
                , div [ class "sub header" ]
                    [ text "Id: "
                    , text model.formModel.equipment.id
                    ]
                ]
        , Html.map FormMsg (Comp.EquipmentForm.view model.formModel)
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible", Util.Maybe.isEmpty model.formError )
                ]
            ]
            [ Maybe.withDefault "" model.formError |> text
            ]
        , div [ class "ui horizontal divider" ] []
        , button [ class "ui primary button", type_ "submit" ]
            [ text "Submit"
            ]
        , a [ class "ui secondary button", onClick (SetViewMode Table), href "" ]
            [ text "Cancel"
            ]
        , if not newEquipment then
            a [ class "ui right floated red button", href "", onClick RequestDelete ]
                [ text "Delete" ]

          else
            span [] []
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
