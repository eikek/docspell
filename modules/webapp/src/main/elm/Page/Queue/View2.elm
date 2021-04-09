module Page.Queue.View2 exposing (viewContent, viewSidebar)

import Api.Model.JobDetail exposing (JobDetail)
import Api.Model.JobLogEvent exposing (JobLogEvent)
import Comp.Progress
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.Priority
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.QueuePage exposing (Texts)
import Page.Queue.Data exposing (..)
import Styles as S
import Util.Time exposing (formatDateTime, formatIsoDateTime)


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible _ _ model =
    let
        count v =
            case v of
                CurrentJobs ->
                    List.length model.state.progress

                QueueAll ->
                    List.length model.state.queued
                        + List.length model.state.completed

                QueueWaiting ->
                    List.length model.state.queued

                QueueSuccess ->
                    filterJobDetails model.state.completed "success"
                        |> List.length

                QueueError ->
                    filterJobDetails model.state.completed "failed"
                        |> List.length

        tabLink cls v icon label =
            a
                [ href "#"
                , class S.sidebarLink
                , class cls
                , classList [ ( "bg-blue-100 dark:bg-bluegray-600", model.queueView == v ) ]
                , onClick (SetQueueView v)
                ]
                [ i [ class icon ]
                    []
                , div
                    [ class "ml-3" ]
                    [ text label ]
                , div [ class "ml-auto bg-gray-200 border rounded-full h-6 w-6 flex items-center justify-center text-xs dark:bg-bluegray-800 dark:text-bluegray-200 dark:border-bluegray-800 dark:bg-opacity-50" ]
                    [ count v |> String.fromInt |> text
                    ]
                ]
    in
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ div [ class "" ]
            [ h1 [ class S.header1 ]
                [ text "Processing Queue"
                ]
            ]
        , div [ class "flex flex-col my-2" ]
            [ tabLink "" CurrentJobs "fa fa-play-circle" texts.currentlyRunning
            , tabLink "" QueueAll "fa fa-hourglass-half" texts.queue
            , tabLink "ml-8" QueueWaiting "fa fa-clock" texts.waiting
            , tabLink "ml-8" QueueError "fa fa-bolt" texts.errored
            , tabLink "ml-8" QueueSuccess "fa fa-check" texts.success
            ]
        ]


viewContent : Texts -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts _ _ model =
    let
        gridStyle =
            "grid gap-4 grid-cols-1 md:grid-cols-2"

        message str =
            div [ class "h-28 flex flex-col items-center justify-center w-full" ]
                [ div [ class S.header2 ]
                    [ text str
                    ]
                ]
    in
    div
        [ class "py-2"
        , class S.content
        ]
        [ case model.showLog of
            Just job ->
                renderJobLog job

            Nothing ->
                span [ class "hidden" ] []
        , case model.queueView of
            CurrentJobs ->
                if List.isEmpty model.state.progress then
                    message texts.noJobsRunning

                else
                    div [ class "flex flex-col space-y-2" ]
                        (List.map (renderProgressCard texts model) model.state.progress)

            QueueAll ->
                if List.isEmpty model.state.completed && List.isEmpty model.state.completed then
                    message texts.noJobsDisplay

                else
                    div [ class gridStyle ]
                        (List.map (renderInfoCard texts model)
                            (model.state.queued ++ model.state.completed)
                        )

            QueueWaiting ->
                if List.isEmpty model.state.queued then
                    message texts.noJobsWaiting

                else
                    div [ class gridStyle ]
                        (List.map (renderInfoCard texts model) model.state.queued)

            QueueError ->
                let
                    items =
                        filterJobDetails model.state.completed "failed"
                in
                if List.isEmpty items then
                    message texts.noJobsFailed

                else
                    div [ class gridStyle ]
                        (List.map (renderInfoCard texts model) items)

            QueueSuccess ->
                let
                    items =
                        filterJobDetails model.state.completed "success"
                in
                if List.isEmpty items then
                    message texts.noJobsSuccess

                else
                    div [ class gridStyle ]
                        (List.map (renderInfoCard texts model) items)
        ]


filterJobDetails : List JobDetail -> String -> List JobDetail
filterJobDetails list state =
    let
        isState job =
            state == job.state
    in
    List.filter isState list


renderJobLog : JobDetail -> Html Msg
renderJobLog job =
    div
        [ class " absolute top-12 left-0 w-full h-full-12 z-40 flex flex-col items-center px-4 py-2 "
        , class "bg-white bg-opacity-80 dark:bg-black dark:bg-bluegray-900 dark:bg-opacity-90"
        ]
        [ div [ class (S.box ++ "py-2 px-2 flex flex-col w-full") ]
            [ div [ class "flex flex-row mb-4 px-2" ]
                [ span [ class "font-semibold" ]
                    [ text job.name
                    ]
                , div [ class "flex-grow flex flex-row justify-end" ]
                    [ a
                        [ href "#"
                        , class S.link
                        , onClick QuitShowLog
                        ]
                        [ i [ class "fa fa-times" ] []
                        ]
                    ]
                ]
            , div [ class styleJobLog ]
                (List.map renderLogLine job.logs)
            ]
        ]


renderProgressCard : Texts -> Model -> JobDetail -> Html Msg
renderProgressCard texts model job =
    div [ class (S.box ++ "px-2 flex flex-col") ]
        [ Comp.Progress.topAttachedIndicating job.progress
        , Html.map (DimmerMsg job)
            (Comp.YesNoDimmer.viewN
                (model.cancelJobRequest == Just job.id)
                (dimmerSettings texts)
                model.deleteConfirm
            )
        , div [ class "py-2 flex flex-row x-space-2 items-center" ]
            [ div [ class "flex flex-row items-center py-0.5" ]
                [ i [ class "fa fa-circle-notch animate-spin" ] []
                , span [ class "ml-2" ]
                    [ text job.name
                    ]
                ]
            , div [ class "flex-grow flex flex-row items-center justify-end" ]
                [ div [ class S.basicLabel ]
                    [ text job.state
                    , div [ class "ml-3" ]
                        [ Maybe.withDefault "" job.worker |> text
                        ]
                    ]
                , div [ class (S.basicLabel ++ "ml-2") ]
                    [ i [ class "fa fa-clock" ] []
                    , div [ class "ml-3" ]
                        [ getDuration model job |> Maybe.withDefault "-:-" |> text
                        ]
                    ]
                ]
            ]
        , div [ class "py-2", id "joblog" ]
            [ div [ class styleJobLog ]
                (List.map renderLogLine job.logs)
            ]
        , div [ class "py-2 flex flex-row justify-end" ]
            [ button [ class S.secondaryButton, onClick (RequestCancelJob job) ]
                [ text texts.basics.cancel
                ]
            ]
        ]


styleJobLog : String
styleJobLog =
    "bg-gray-900 text-xs leading-5 px-2 py-1 font-mono text-gray-100 overflow-auto max-h-96 rounded"


renderLogLine : JobLogEvent -> Html Msg
renderLogLine log =
    let
        lineStyle =
            case String.toLower log.level of
                "info" ->
                    ""

                "debug" ->
                    "opacity-50"

                "warn" ->
                    "text-yellow-400"

                "error" ->
                    "text-red-400"

                _ ->
                    ""
    in
    span [ class lineStyle ]
        [ formatIsoDateTime log.time |> text
        , text ": "
        , text log.message
        , br [] []
        ]


isFinal : JobDetail -> Bool
isFinal job =
    case job.state of
        "failed" ->
            True

        "success" ->
            True

        "cancelled" ->
            True

        _ ->
            False


dimmerSettings : Texts -> Comp.YesNoDimmer.Settings
dimmerSettings texts =
    let
        defaults =
            Comp.YesNoDimmer.defaultSettings texts.deleteThisJob texts.basics.yes texts.basics.no
    in
    { defaults
        | headerClass = "text-lg text-white"
        , headerIcon = ""
        , extraClass = "rounded"
    }


renderInfoCard : Texts -> Model -> JobDetail -> Html Msg
renderInfoCard texts model job =
    let
        prio =
            Data.Priority.fromString job.priority
                |> Maybe.withDefault Data.Priority.Low

        color solid =
            jobStateColor job solid

        labelStyle solid =
            " label min-h-6 inline text-xs font-semibold " ++ color solid ++ " "
    in
    div
        [ class (S.box ++ "px-4 py-4 flex flex-col rounded relative")
        ]
        [ Html.map (DimmerMsg job)
            (Comp.YesNoDimmer.viewN
                (model.cancelJobRequest == Just job.id)
                (dimmerSettings texts)
                model.deleteConfirm
            )
        , div [ class "flex flex-row" ]
            [ div [ class "flex-grow items-center" ]
                [ i
                    [ classList
                        [ ( "fa fa-check", job.state == "success" )
                        , ( "fa fa-redo", job.state == "stuck" )
                        , ( "fa fa-bolt", job.state == "failed" )
                        , ( "fa fa-meh-outline", job.state == "canceled" )
                        , ( "fa fa-cog", not (isFinal job) && job.state /= "stuck" )
                        ]
                    , class "justify-center"
                    ]
                    []
                , div [ class (labelStyle True ++ " ml-2") ]
                    [ text job.state
                    ]
                , div [ class "ml-2 break-all hidden sm:inline-block" ]
                    [ text job.name
                    ]
                ]
            , div [ class "flex flex-row space-x-2" ]
                [ a
                    [ onClick (ShowLog job)
                    , href "#"
                    , class S.link
                    , classList [ ( "hidden", not (isFinal job || job.state == "stuck") ) ]
                    ]
                    [ i
                        [ class "fa fa-file"
                        , title texts.showLog
                        ]
                        []
                    ]
                , a
                    [ title texts.remove
                    , href "#"
                    , class S.link
                    , onClick (RequestCancelJob job)
                    ]
                    [ i
                        [ class "fa fa-times"
                        ]
                        []
                    ]
                , div
                    [ classList [ ( "hidden", isFinal job ) ]
                    ]
                    [ div [ class "font-mono" ]
                        [ getDuration model job |> Maybe.withDefault "3:12" |> text
                        ]
                    ]
                ]
            ]
        , div [ class "sm:hidden mt-1 break-all" ]
            [ text job.name
            ]
        , div [ class "my-2" ]
            [ hr [ class S.border ] []
            ]
        , div [ class "flex flex-row space-x-2 items-center flex-wrap" ]
            [ div [ class "flex flex-row justify-start " ]
                [ div [ class "text-xs font-semibold" ]
                    [ Util.Time.formatDateTime job.submitted |> text
                    ]
                ]
            , div [ class "flex-grow flex flex-row justify-end space-x-2 flex-wrap" ]
                [ div
                    [ class (labelStyle False)
                    , classList [ ( "hidden", not (isFinal job) ) ]
                    ]
                    [ i [ class "fa fa-clock mr-3" ] []
                    , span []
                        [ getDuration model job |> Maybe.withDefault "-:-" |> text
                        ]
                    ]
                , div [ class (labelStyle False) ]
                    [ span [ class "mr-3" ]
                        [ text texts.retries
                        ]
                    , span []
                        [ job.retries |> String.fromInt |> text
                        ]
                    ]
                , case job.state of
                    "waiting" ->
                        a
                            [ class (labelStyle False)
                            , onClick (ChangePrio job.id (Data.Priority.next prio))
                            , href "#"
                            , title texts.changePriority
                            ]
                            [ i [ class "sort numeric up icon" ] []
                            , text "Prio"
                            , div [ class "detail" ]
                                [ code []
                                    [ Data.Priority.fromString job.priority
                                        |> Maybe.map Data.Priority.toName
                                        |> Maybe.withDefault job.priority
                                        |> text
                                    ]
                                ]
                            ]

                    _ ->
                        div
                            [ class (labelStyle False)
                            ]
                            [ span [ class "mr-3" ]
                                [ text texts.prio
                                ]
                            , code [ class "font-mono" ]
                                [ Data.Priority.fromString job.priority
                                    |> Maybe.map Data.Priority.toName
                                    |> Maybe.withDefault job.priority
                                    |> text
                                ]
                            ]
                ]
            ]
        ]


jobStateColor : JobDetail -> Bool -> String
jobStateColor job solid =
    case job.state of
        "success" ->
            if solid then
                S.greenSolidLabel

            else
                S.greenBasicLabel

        "failed" ->
            if solid then
                S.redSolidLabel

            else
                S.redBasicLabel

        "canceled" ->
            "text-orange-500 border-orange-500"

        "stuck" ->
            "text-purple-500 border-purple-500"

        "scheduled" ->
            "text-blue-500 border-blue-500"

        "waiting" ->
            "text-gray-500 border-gray-500"

        _ ->
            ""
