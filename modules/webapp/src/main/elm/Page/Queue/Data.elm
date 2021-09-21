{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Queue.Data exposing
    ( FormState(..)
    , Model
    , Msg(..)
    , QueueView(..)
    , emptyModel
    , getDuration
    , getRunningTime
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.JobDetail exposing (JobDetail)
import Api.Model.JobQueueState exposing (JobQueueState)
import Comp.YesNoDimmer
import Data.Priority exposing (Priority)
import Http
import Time
import Util.Duration
import Util.Maybe


type alias Model =
    { state : JobQueueState
    , formState : FormState
    , pollingInterval : Float
    , init : Bool
    , stopRefresh : Bool
    , currentMillis : Int
    , showLog : Maybe JobDetail
    , deleteConfirm : Comp.YesNoDimmer.Model
    , cancelJobRequest : Maybe String
    , queueView : QueueView
    }


type FormState
    = InitialForm
    | HttpError Http.Error


type QueueView
    = CurrentJobs
    | QueueAll
    | QueueWaiting
    | QueueError
    | QueueSuccess
    | QueueCancelled


emptyModel : Model
emptyModel =
    { state = Api.Model.JobQueueState.empty
    , formState = InitialForm
    , pollingInterval = 1200
    , init = False
    , stopRefresh = False
    , currentMillis = 0
    , showLog = Nothing
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , cancelJobRequest = Nothing
    , queueView = CurrentJobs
    }


type Msg
    = Init
    | StateResp (Result Http.Error JobQueueState)
    | StopRefresh
    | NewTime Time.Posix
    | ShowLog JobDetail
    | QuitShowLog
    | RequestCancelJob JobDetail
    | DimmerMsg JobDetail Comp.YesNoDimmer.Msg
    | CancelResp (Result Http.Error BasicResult)
    | ChangePrio String Priority
    | SetQueueView QueueView


getRunningTime : Model -> JobDetail -> Maybe String
getRunningTime model job =
    let
        mkTime : Int -> Int -> Maybe String
        mkTime start end =
            if start < end then
                Just <| Util.Duration.toHuman (end - start)

            else
                Nothing
    in
    case ( job.started, job.finished ) of
        ( Just sn, Just fn ) ->
            Util.Maybe.or
                [ mkTime sn fn
                , mkTime sn model.currentMillis
                ]

        ( Just sn, Nothing ) ->
            mkTime sn model.currentMillis

        ( Nothing, _ ) ->
            Nothing


getSubmittedTime : Model -> JobDetail -> Maybe String
getSubmittedTime model job =
    if model.currentMillis > job.submitted then
        Just <| Util.Duration.toHuman (model.currentMillis - job.submitted)

    else
        Nothing


getDuration : Model -> JobDetail -> Maybe String
getDuration model job =
    if job.state == "stuck" then
        getSubmittedTime model job

    else
        Util.Maybe.or [ getRunningTime model job, getSubmittedTime model job ]
