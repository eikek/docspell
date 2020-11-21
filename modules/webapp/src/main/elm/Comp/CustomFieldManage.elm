module Comp.CustomFieldManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
    , view
    )

import Api
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Comp.CustomFieldForm
import Comp.CustomFieldTable
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http


type alias Model =
    { tableModel : Comp.CustomFieldTable.Model
    , detailModel : Maybe Comp.CustomFieldForm.Model
    , fields : List CustomField
    , query : String
    , loading : Bool
    }


type Msg
    = TableMsg Comp.CustomFieldTable.Msg
    | DetailMsg Comp.CustomFieldForm.Msg
    | CustomFieldListResp (Result Http.Error CustomFieldList)
    | SetQuery String
    | InitNewCustomField


empty : Model
empty =
    { tableModel = Comp.CustomFieldTable.init
    , detailModel = Nothing
    , fields = []
    , query = ""
    , loading = False
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( empty
    , Api.getCustomFields flags empty.query CustomFieldListResp
    )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg lm ->
            let
                ( tm, action ) =
                    Comp.CustomFieldTable.update lm model.tableModel

                detail =
                    case action of
                        Comp.CustomFieldTable.EditAction item ->
                            Comp.CustomFieldForm.init item |> Just

                        Comp.CustomFieldTable.NoAction ->
                            model.detailModel
            in
            ( { model | tableModel = tm, detailModel = detail }, Cmd.none )

        DetailMsg lm ->
            case model.detailModel of
                Just detail ->
                    let
                        ( dm, dc, back ) =
                            Comp.CustomFieldForm.update flags lm detail

                        cmd =
                            if back then
                                Api.getCustomFields flags model.query CustomFieldListResp

                            else
                                Cmd.none
                    in
                    ( { model
                        | detailModel =
                            if back then
                                Nothing

                            else
                                Just dm
                      }
                    , Cmd.batch
                        [ Cmd.map DetailMsg dc
                        , cmd
                        ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        SetQuery str ->
            ( { model | query = str }
            , Api.getCustomFields flags str CustomFieldListResp
            )

        CustomFieldListResp (Ok sl) ->
            ( { model | fields = sl.items }, Cmd.none )

        CustomFieldListResp (Err _) ->
            ( model, Cmd.none )

        InitNewCustomField ->
            let
                sd =
                    Comp.CustomFieldForm.initEmpty
            in
            ( { model | detailModel = Just sd }
            , Cmd.none
            )



--- View


view : Flags -> Model -> Html Msg
view flags model =
    case model.detailModel of
        Just dm ->
            viewDetail flags dm

        Nothing ->
            viewTable model


viewDetail : Flags -> Comp.CustomFieldForm.Model -> Html Msg
viewDetail flags detailModel =
    let
        viewSettings =
            Comp.CustomFieldForm.fullViewSettings
    in
    div []
        [ Html.map DetailMsg (Comp.CustomFieldForm.view viewSettings detailModel)
        ]


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
                        , onClick InitNewCustomField
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New CustomField"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.CustomFieldTable.view model.tableModel model.fields)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
