{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.CustomFieldManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
    , view2
    )

import Api
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldList exposing (CustomFieldList)
import Comp.Basic as B
import Comp.CustomFieldForm
import Comp.CustomFieldTable
import Comp.MenuBar as MB
import Data.CustomFieldOrder exposing (CustomFieldOrder)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.CustomFieldManage exposing (Texts)
import Styles as S
import Util.CustomField


type alias Model =
    { tableModel : Comp.CustomFieldTable.Model
    , detailModel : Maybe Comp.CustomFieldForm.Model
    , fields : List CustomField
    , query : String
    , loading : Bool
    , order : CustomFieldOrder
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
    , order = Data.CustomFieldOrder.LabelAsc
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( empty
    , loadFields flags empty
    )



--- Update


loadFields : Flags -> Model -> Cmd Msg
loadFields flags model =
    Api.getCustomFields flags model.query model.order CustomFieldListResp


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg lm ->
            let
                ( tm, action, maybeOrder ) =
                    Comp.CustomFieldTable.update lm model.tableModel

                newOrder =
                    Maybe.withDefault model.order maybeOrder

                detail =
                    case action of
                        Comp.CustomFieldTable.EditAction item ->
                            Comp.CustomFieldForm.init item |> Just

                        Comp.CustomFieldTable.NoAction ->
                            model.detailModel

                newModel =
                    { model
                        | tableModel = tm
                        , detailModel = detail
                        , order = newOrder
                    }

                ( m1, c1 ) =
                    if model.order == newOrder then
                        ( newModel, Cmd.none )

                    else
                        ( newModel, loadFields flags newModel )
            in
            ( m1, c1 )

        DetailMsg lm ->
            case model.detailModel of
                Just detail ->
                    let
                        ( dm, dc, back ) =
                            Comp.CustomFieldForm.update flags lm detail

                        cmd =
                            if back then
                                loadFields flags model

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
            let
                newModel =
                    { model | query = str }
            in
            ( newModel
            , loadFields flags newModel
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



--- View2


view2 : Texts -> Flags -> Model -> Html Msg
view2 texts flags model =
    case model.detailModel of
        Just dm ->
            viewDetail2 texts flags dm

        Nothing ->
            viewTable2 texts model


viewDetail2 : Texts -> Flags -> Comp.CustomFieldForm.Model -> Html Msg
viewDetail2 texts _ detailModel =
    let
        viewSettings =
            { showControls = True
            , classes = ""
            }
    in
    div []
        ((if detailModel.field.id == "" then
            h3 [ class S.header2 ]
                [ text texts.newCustomField
                ]

          else
            h3 [ class S.header2 ]
                [ Util.CustomField.nameOrLabel detailModel.field |> text
                , div [ class "opacity-50 text-sm" ]
                    [ text (texts.basics.id ++ ": ")
                    , text detailModel.field.id
                    ]
                ]
         )
            :: List.map (Html.map DetailMsg)
                (Comp.CustomFieldForm.view2 texts.fieldForm
                    viewSettings
                    detailModel
                )
        )


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col md:relative" ]
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
                    { tagger = InitNewCustomField
                    , title = texts.addCustomField
                    , icon = Just "fa fa-plus"
                    , label = texts.newCustomField
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg
            (Comp.CustomFieldTable.view2 texts.fieldTable
                model.order
                model.tableModel
                model.fields
            )
        , B.loadingDimmer
            { active = model.loading
            , label = texts.basics.loading
            }
        ]
