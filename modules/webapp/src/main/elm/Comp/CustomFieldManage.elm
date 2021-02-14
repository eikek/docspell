module Comp.CustomFieldManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
    , view
    , view2
    )

import Api
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Comp.Basic as B
import Comp.CustomFieldForm
import Comp.CustomFieldTable
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Styles as S
import Util.CustomField


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



--- View2


view2 : Flags -> Model -> Html Msg
view2 flags model =
    case model.detailModel of
        Just dm ->
            viewDetail2 flags dm

        Nothing ->
            viewTable2 model


viewDetail2 : Flags -> Comp.CustomFieldForm.Model -> Html Msg
viewDetail2 _ detailModel =
    let
        viewSettings =
            Comp.CustomFieldForm.fullViewSettings
    in
    div []
        ([ if detailModel.field.id == "" then
            h3 [ class S.header2 ]
                [ text "Create new custom field"
                ]

           else
            h3 [ class S.header2 ]
                [ Util.CustomField.nameOrLabel detailModel.field |> text
                , div [ class "opacity-50 text-sm" ]
                    [ text "Id: "
                    , text detailModel.field.id
                    ]
                ]
         ]
            ++ List.map (Html.map DetailMsg) (Comp.CustomFieldForm.view2 viewSettings detailModel)
        )


viewTable2 : Model -> Html Msg
viewTable2 model =
    div [ class "flex flex-col md:relative" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = "Search…"
                    , icon = Just "fa fa-search"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewCustomField
                    , title = "Add a new custom field"
                    , icon = Just "fa fa-plus"
                    , label = "New custom field"
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.CustomFieldTable.view2 model.tableModel model.fields)
        , B.loadingDimmer model.loading
        ]
