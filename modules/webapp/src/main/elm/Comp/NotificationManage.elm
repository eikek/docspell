{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationManage exposing
    ( Model
    , Msg
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.NotificationSettingsList exposing (NotificationSettingsList)
import Comp.MenuBar as MB
import Comp.NotificationForm
import Comp.NotificationList
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.Comp.NotificationManage exposing (Texts)
import Styles as S


type alias Model =
    { listModel : Comp.NotificationList.Model
    , detailModel : Maybe Comp.NotificationForm.Model
    , items : List NotificationSettings
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
    = ListMsg Comp.NotificationList.Msg
    | DetailMsg Comp.NotificationForm.Msg
    | GetDataResp (Result Http.Error NotificationSettingsList)
    | NewTask
    | SubmitResp SubmitType (Result Http.Error BasicResult)


initModel : Model
initModel =
    { listModel = Comp.NotificationList.init
    , detailModel = Nothing
    , items = []
    , formState = FormStateInitial
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getNotifyDueItems flags GetDataResp


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
                    Comp.NotificationList.update lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.NotificationList.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.NotificationList.EditAction settings ->
                            let
                                ( dm, dc ) =
                                    Comp.NotificationForm.initWith flags settings
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
                            Comp.NotificationForm.update flags lm dm

                        ( model_, cmd_ ) =
                            case action of
                                Comp.NotificationForm.NoAction ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , Cmd.none
                                    )

                                Comp.NotificationForm.SubmitAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , if settings.id == "" then
                                        Api.createNotifyDueItems flags settings (SubmitResp SubmitCreate)

                                      else
                                        Api.updateNotifyDueItems flags settings (SubmitResp SubmitUpdate)
                                    )

                                Comp.NotificationForm.CancelAction ->
                                    ( { model
                                        | detailModel = Nothing
                                        , formState = FormStateInitial
                                      }
                                    , initCmd flags
                                    )

                                Comp.NotificationForm.StartOnceAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , Api.startOnceNotifyDueItems flags settings (SubmitResp SubmitStartOnce)
                                    )

                                Comp.NotificationForm.DeleteAction id ->
                                    ( { model
                                        | detailModel = Just mm
                                        , formState = FormStateInitial
                                      }
                                    , Api.deleteNotifyDueItems flags id (SubmitResp SubmitDelete)
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
                    Comp.NotificationForm.init flags
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


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
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


viewForm2 : Texts -> UiSettings -> Comp.NotificationForm.Model -> List (Html Msg)
viewForm2 texts settings model =
    [ Html.map DetailMsg
        (Comp.NotificationForm.view2 texts.notificationForm "flex flex-col" settings model)
    ]


viewList2 : Texts -> Model -> List (Html Msg)
viewList2 texts model =
    [ MB.view
        { start =
            [ MB.PrimaryButton
                { tagger = NewTask
                , label = texts.newTask
                , icon = Just "fa fa-plus"
                , title = texts.createNewTask
                }
            ]
        , end = []
        , rootClasses = "mb-4"
        }
    , Html.map ListMsg
        (Comp.NotificationList.view2 texts.notificationTable
            model.listModel
            model.items
        )
    ]
