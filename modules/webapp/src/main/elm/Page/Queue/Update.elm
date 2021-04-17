module Page.Queue.Update exposing (update)

import Api
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Page.Queue.Data exposing (..)
import Task
import Time


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        Init ->
            let
                start =
                    if model.init then
                        Cmd.none

                    else
                        Cmd.batch
                            [ Api.getJobQueueState flags StateResp
                            , getNewTime
                            ]
            in
            ( { model | init = True, stopRefresh = False }, start )

        StateResp (Ok s) ->
            let
                refresh =
                    if model.pollingInterval <= 0 || model.stopRefresh then
                        Cmd.none

                    else
                        Cmd.batch
                            [ Api.getJobQueueStateIn flags model.pollingInterval StateResp
                            , getNewTime
                            ]
            in
            ( { model | state = s, stopRefresh = False }, refresh )

        StateResp (Err err) ->
            ( { model | formState = HttpError err }, Cmd.none )

        StopRefresh ->
            ( { model | stopRefresh = True, init = False }, Cmd.none )

        NewTime t ->
            ( { model | currentMillis = Time.posixToMillis t }, Cmd.none )

        ShowLog job ->
            ( { model | showLog = Just job }, Cmd.none )

        QuitShowLog ->
            ( { model | showLog = Nothing }, Cmd.none )

        RequestCancelJob job ->
            let
                newModel =
                    { model | cancelJobRequest = Just job.id }
            in
            update flags (DimmerMsg job Comp.YesNoDimmer.Activate) newModel

        DimmerMsg job m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                cmd =
                    if confirmed then
                        Api.cancelJob flags job.id CancelResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )

        CancelResp (Ok _) ->
            ( model, Cmd.none )

        CancelResp (Err _) ->
            ( model, Cmd.none )

        ChangePrio id prio ->
            ( model, Api.setJobPrio flags id prio CancelResp )

        SetQueueView v ->
            ( { model | queueView = v }, Cmd.none )


getNewTime : Cmd Msg
getNewTime =
    Task.perform NewTime Time.now
