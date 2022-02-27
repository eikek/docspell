{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ScanMailboxManage exposing
    ( Model
    , Msg
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Api.Model.ScanMailboxSettingsList exposing (ScanMailboxSettingsList)
import Comp.MenuBar as MB
import Comp.ScanMailboxForm
import Comp.ScanMailboxList
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.ScanMailboxManage exposing (Texts)
import Styles as S


type alias Model =
    { listModel : Comp.ScanMailboxList.Model
    , detailModel : Maybe Comp.ScanMailboxForm.Model
    , items : List ScanMailboxSettings
    , formState : FormState
    }


type SubmitType
    = SubmitDelete
    | SubmitUpdate
    | SubmitCreate
    | SubmitStartOnce


type FormState
    = FormStateInitial
    | FormHttpError Http.Error
    | FormSubmitSuccessful SubmitType
    | FormSubmitFailed String


type Msg
    = ListMsg Comp.ScanMailboxList.Msg
    | DetailMsg Comp.ScanMailboxForm.Msg
    | GetDataResp (Result Http.Error ScanMailboxSettingsList)
    | NewTask
    | SubmitResp SubmitType (Result Http.Error BasicResult)


initModel : Model
initModel =
    { listModel = Comp.ScanMailboxList.init
    , detailModel = Nothing
    , items = []
    , formState = FormStateInitial
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getScanMailbox flags GetDataResp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initModel, initCmd flags )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        GetDataResp (Ok res) ->
            ( { model
                | items = res.items
                , formState = FormStateInitial
              }
            , Cmd.none
            )

        GetDataResp (Err err) ->
            ( { model | formState = FormHttpError err }
            , Cmd.none
            )

        ListMsg lm ->
            let
                ( mm, action ) =
                    Comp.ScanMailboxList.update lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.ScanMailboxList.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.ScanMailboxList.EditAction settings ->
                            let
                                ( dm, dc ) =
                                    Comp.ScanMailboxForm.initWith flags settings
                            in
                            ( Just dm, Cmd.map DetailMsg dc )
            in
            ( { model
                | listModel = mm
                , detailModel = detail
              }
            , cmd
            )

        DetailMsg lm ->
            case model.detailModel of
                Just dm ->
                    let
                        ( mm, action, mc ) =
                            Comp.ScanMailboxForm.update flags lm dm

                        ( model_, cmd_ ) =
                            case action of
                                Comp.ScanMailboxForm.NoAction ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , Cmd.none
                                    )

                                Comp.ScanMailboxForm.SubmitAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , if settings.id == "" then
                                        Api.createScanMailbox flags settings (SubmitResp SubmitCreate)

                                      else
                                        Api.updateScanMailbox flags settings (SubmitResp SubmitUpdate)
                                    )

                                Comp.ScanMailboxForm.CancelAction ->
                                    ( { model
                                        | detailModel = Nothing
                                        , formState = FormStateInitial
                                      }
                                    , initCmd flags
                                    )

                                Comp.ScanMailboxForm.StartOnceAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , Api.startOnceScanMailbox flags settings (SubmitResp SubmitStartOnce)
                                    )

                                Comp.ScanMailboxForm.DeleteAction id ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , Api.deleteScanMailbox flags id (SubmitResp SubmitDelete)
                                    )
                    in
                    ( model_
                    , Cmd.batch
                        [ Cmd.map DetailMsg mc
                        , cmd_
                        ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        NewTask ->
            let
                ( mm, mc ) =
                    Comp.ScanMailboxForm.init flags
            in
            ( { model | detailModel = Just mm }, Cmd.map DetailMsg mc )

        SubmitResp submitType (Ok res) ->
            ( { model
                | formState =
                    if res.success then
                        FormSubmitSuccessful submitType

                    else
                        FormSubmitFailed res.message
                , detailModel =
                    if submitType == SubmitDelete then
                        Nothing

                    else
                        model.detailModel
              }
            , if submitType == SubmitDelete then
                initCmd flags

              else
                Cmd.none
            )

        SubmitResp _ (Err err) ->
            ( { model | formState = FormHttpError err }
            , Cmd.none
            )



--- View2


view2 : Texts -> Flags -> UiSettings -> Model -> Html Msg
view2 texts flags settings model =
    div [ class "flex flex-col" ]
        (div
            [ classList
                [ ( S.errorMessage, model.formState /= FormStateInitial )
                , ( S.successMessage, isSuccess model.formState )
                , ( "hidden", model.formState == FormStateInitial )
                ]
            , class "mb-2"
            ]
            [ case model.formState of
                FormStateInitial ->
                    text ""

                FormSubmitSuccessful SubmitCreate ->
                    text texts.taskCreated

                FormSubmitSuccessful SubmitUpdate ->
                    text texts.taskUpdated

                FormSubmitSuccessful SubmitStartOnce ->
                    text texts.taskStarted

                FormSubmitSuccessful SubmitDelete ->
                    text texts.taskDeleted

                FormSubmitFailed m ->
                    text m

                FormHttpError err ->
                    text (texts.httpError err)
            ]
            :: (case model.detailModel of
                    Just msett ->
                        viewForm2 texts flags settings msett

                    Nothing ->
                        viewList2 texts model
               )
        )


isSuccess : FormState -> Bool
isSuccess state =
    case state of
        FormSubmitSuccessful _ ->
            True

        _ ->
            False


viewForm2 : Texts -> Flags -> UiSettings -> Comp.ScanMailboxForm.Model -> List (Html Msg)
viewForm2 texts flags settings model =
    [ Html.map DetailMsg
        (Comp.ScanMailboxForm.view2 texts.form flags "" settings model)
    ]


viewList2 : Texts -> Model -> List (Html Msg)
viewList2 texts model =
    [ MB.view
        { start = []
        , end =
            [ MB.PrimaryButton
                { tagger = NewTask
                , label = texts.newTask
                , icon = Just "fa fa-plus"
                , title = texts.createNewTask
                }
            ]
        , rootClasses = "mb-4"
        , sticky = True
        }
    , Html.map ListMsg
        (Comp.ScanMailboxList.view2 texts.table
            model.listModel
            model.items
        )
    ]
