{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.PeriodicQueryTaskManage exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.PeriodicQuerySettings exposing (PeriodicQuerySettings)
import Comp.ChannelMenu
import Comp.MenuBar as MB
import Comp.PeriodicQueryTaskForm
import Comp.PeriodicQueryTaskList
import Data.ChannelType exposing (ChannelType)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.PeriodicQueryTaskManage exposing (Texts)
import Styles as S


type alias Model =
    { listModel : Comp.PeriodicQueryTaskList.Model
    , detailModel : Maybe Comp.PeriodicQueryTaskForm.Model
    , items : List PeriodicQuerySettings
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
    = ListMsg Comp.PeriodicQueryTaskList.Msg
    | DetailMsg Comp.PeriodicQueryTaskForm.Msg
    | GetDataResp (Result Http.Error (List PeriodicQuerySettings))
    | NewTaskInit
    | SubmitResp SubmitType (Result Http.Error BasicResult)


initModel : Model
initModel =
    { listModel = Comp.PeriodicQueryTaskList.init
    , detailModel = Nothing
    , items = []
    , formState = FormStateInitial
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getPeriodicQuery flags GetDataResp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initModel, initCmd flags )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        GetDataResp (Ok items) ->
            ( { model
                | items = items
                , formState = FormStateInitial
              }
            , Cmd.none
            , Sub.none
            )

        GetDataResp (Err err) ->
            ( { model | formState = FormHttpError err }
            , Cmd.none
            , Sub.none
            )

        ListMsg lm ->
            let
                ( mm, action ) =
                    Comp.PeriodicQueryTaskList.update lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.PeriodicQueryTaskList.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.PeriodicQueryTaskList.EditAction settings ->
                            let
                                ( dm, dc ) =
                                    Comp.PeriodicQueryTaskForm.initWith flags settings
                            in
                            ( Just dm, Cmd.map DetailMsg dc )
            in
            ( { model
                | listModel = mm
                , detailModel = detail
              }
            , cmd
            , Sub.none
            )

        DetailMsg lm ->
            case model.detailModel of
                Just dm ->
                    let
                        --( mm, action, mc ) =
                        result =
                            Comp.PeriodicQueryTaskForm.update flags lm dm

                        ( model_, cmd_ ) =
                            case result.action of
                                Comp.PeriodicQueryTaskForm.NoAction ->
                                    ( { model
                                        | detailModel = Just result.model
                                        , formState = FormStateInitial
                                      }
                                    , Cmd.none
                                    )

                                Comp.PeriodicQueryTaskForm.SubmitAction settings ->
                                    ( { model
                                        | detailModel = Just result.model
                                        , formState = FormStateInitial
                                      }
                                    , if settings.id == "" then
                                        Api.createPeriodicQuery flags settings (SubmitResp SubmitCreate)

                                      else
                                        Api.updatePeriodicQuery flags settings (SubmitResp SubmitUpdate)
                                    )

                                Comp.PeriodicQueryTaskForm.CancelAction ->
                                    ( { model
                                        | detailModel = Nothing
                                        , formState = FormStateInitial
                                      }
                                    , initCmd flags
                                    )

                                Comp.PeriodicQueryTaskForm.StartOnceAction settings ->
                                    ( { model
                                        | detailModel = Just result.model
                                        , formState = FormStateInitial
                                      }
                                    , Api.startOncePeriodicQuery flags settings (SubmitResp SubmitStartOnce)
                                    )

                                Comp.PeriodicQueryTaskForm.DeleteAction id ->
                                    ( { model
                                        | detailModel = Just result.model
                                        , formState = FormStateInitial
                                      }
                                    , Api.deletePeriodicQueryTask flags id (SubmitResp SubmitDelete)
                                    )
                    in
                    ( model_
                    , Cmd.batch
                        [ Cmd.map DetailMsg result.cmd
                        , cmd_
                        ]
                    , Sub.map DetailMsg result.sub
                    )

                Nothing ->
                    ( model, Cmd.none, Sub.none )

        NewTaskInit ->
            let
                ( mm, mc ) =
                    Comp.PeriodicQueryTaskForm.init flags
            in
            ( { model | detailModel = Just mm }, Cmd.map DetailMsg mc, Sub.none )

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
            , Sub.none
            )

        SubmitResp _ (Err err) ->
            ( { model | formState = FormHttpError err }
            , Cmd.none
            , Sub.none
            )



--- View2


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    div [ class "flex flex-col" ]
        (div
            [ classList
                [ ( S.errorMessage, not <| isSuccess model.formState )
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
                        viewForm2 texts settings msett

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


viewForm2 : Texts -> UiSettings -> Comp.PeriodicQueryTaskForm.Model -> List (Html Msg)
viewForm2 texts settings model =
    [ Html.map DetailMsg
        (Comp.PeriodicQueryTaskForm.view texts.notificationForm "flex flex-col" settings model)
    ]


viewList2 : Texts -> Model -> List (Html Msg)
viewList2 texts model =
    [ MB.view
        { start = []
        , end =
            [ MB.PrimaryButton
                { tagger = NewTaskInit
                , title = texts.newTask
                , icon = Just "fa fa-plus"
                , label = texts.newTask
                }
            ]
        , rootClasses = "mb-4"
        }
    , Html.map ListMsg
        (Comp.PeriodicQueryTaskList.view2 texts.notificationTable
            model.listModel
            model.items
        )
    ]
