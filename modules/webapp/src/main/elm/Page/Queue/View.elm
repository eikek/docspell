module Page.Queue.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)

import Page.Queue.Data exposing (..)
import Api.Model.JobQueueState exposing (JobQueueState)
import Api.Model.JobDetail exposing (JobDetail)
import Api.Model.JobLogEvent exposing (JobLogEvent)
import Data.Priority
import Comp.YesNoDimmer
import Util.Time exposing (formatDateTime, formatIsoDateTime)
import Util.Duration

view: Model -> Html Msg
view model =
    div [class "queue-page ui grid container"] <|
        List.concat
             [ case model.showLog of
                   Just job ->
                       [renderJobLog job]
                   Nothing ->
                       List.map (renderProgressCard model) model.state.progress
                           |> List.map (\el -> div [class "row"][div [class "column"][el]])
             , [div [class "two column row"]
                    [renderWaiting model
                    ,renderCompleted model
                    ]
               ]
             ]

renderJobLog: JobDetail -> Html Msg
renderJobLog job =
    div [class "ui fluid card"]
        [div [class "content"]
             [i [class "delete link icon", onClick QuitShowLog][]
             ,text job.name
             ]
        ,div [class "content"]
             [div [class "job-log"]
                  (List.map renderLogLine job.logs)
             ]
        ]


renderWaiting: Model -> Html Msg
renderWaiting model =
    div [class "column"]
        [div [class "ui center aligned basic segment"]
             [i [class "ui large angle double up icon"][]
             ]
        ,div [class "ui centered cards"]
            (List.map (renderInfoCard model) model.state.queued)
        ]

renderCompleted: Model -> Html Msg
renderCompleted model =
    div [class "column"]
        [div [class "ui center aligned basic segment"]
             [i [class "ui large angle double down icon"][]
             ]
        ,div [class "ui centered cards"]
             (List.map (renderInfoCard model) model.state.completed)
        ]

renderProgressCard: Model -> JobDetail -> Html Msg
renderProgressCard model job =
    div [class "ui fluid card"]
        [div [id job.id, class "ui top attached indicating progress"]
             [div [class "bar"]
                  []
             ]
        ,Html.map (DimmerMsg job) (Comp.YesNoDimmer.view2 (model.cancelJobRequest == Just job.id) dimmerSettings model.deleteConfirm)
        ,div [class "content"]
             [ div [class "right floated meta"]
                   [div [class "ui label"]
                       [text job.state
                       ,div [class "detail"]
                           [Maybe.withDefault "" job.worker |> text
                           ]
                       ]
                   ,div [class "ui basic label"]
                       [i [class "clock icon"][]
                       ,div [class "detail"]
                            [getDuration model job |> Maybe.withDefault "-:-" |> text
                            ]
                       ]
                   ]
             , i [class "asterisk loading icon"][]
             , text job.name
             ]
        ,div [class "content"]
             [div [class "job-log"]
                  (List.map renderLogLine job.logs)
             ]
        ,div [class "meta"]
            [div [class "right floated"]
                 [button [class "ui button", onClick (RequestCancelJob job)]
                      [text "Cancel"
                      ]
                 ]
            ]
        ]

renderLogLine: JobLogEvent -> Html Msg
renderLogLine log =
    span [class (String.toLower log.level)]
        [formatIsoDateTime log.time |> text
        ,text ": "
        ,text log.message
        , br[][]
        ]

isFinal: JobDetail -> Bool
isFinal job =
    case job.state of
        "failed" -> True
        "success" -> True
        "cancelled" -> True
        _ -> False

dimmerSettings: Comp.YesNoDimmer.Settings
dimmerSettings =
    let
        defaults = Comp.YesNoDimmer.defaultSettings
    in
        { defaults | headerClass = "ui inverted header", headerIcon = "", message = "Cancel/Delete this job?"}

renderInfoCard: Model -> JobDetail -> Html Msg
renderInfoCard model job =
    div [classList [("ui fluid card", True)
                   ,(jobStateColor job, True)
                   ]
        ]
        [Html.map (DimmerMsg job) (Comp.YesNoDimmer.view2 (model.cancelJobRequest == Just job.id) dimmerSettings model.deleteConfirm)
        ,div [class "content"]
             [div [class "right floated"]
                 [if isFinal job || job.state == "stuck" then
                      span [onClick (ShowLog job)]
                        [i [class "file link icon", title "Show log"][]
                        ]
                  else
                      span[][]
                 ,i [class "delete link icon", title "Remove", onClick (RequestCancelJob job)][]
                 ]
             ,if isFinal job then
                  span [class "invisible"][]
              else
                  div [class "right floated"]
                      [div [class "meta"]
                           [getDuration model job |> Maybe.withDefault "-:-" |> text
                           ]
                      ]
             ,i [classList [("check icon", job.state == "success")
                           ,("redo icon", job.state == "stuck")
                           ,("bolt icon", job.state == "failed")
                           ,("meh outline icon", job.state == "canceled")
                           ,("cog icon", not (isFinal job) && job.state /= "stuck")
                           ]
                ][]
             ,text job.name
             ]
        ,div [class "content"]
            [div [class "right floated"]
                 [if isFinal job then
                      div [class ("ui basic label " ++ jobStateColor job)]
                          [i [class "clock icon"][]
                          ,div [class "detail"]
                               [getDuration model job |> Maybe.withDefault "-:-" |> text
                               ]
                          ]
                  else
                      span [class "invisible"][]
                 ,div [class ("ui basic label " ++ jobStateColor job)]
                      [text "Prio"
                      ,div [class "detail"]
                           [code [][Data.Priority.fromString job.priority
                                    |> Maybe.map Data.Priority.toName
                                    |> Maybe.withDefault job.priority
                                    |> text
                                   ]
                           ]
                      ]
                 ,div [class ("ui basic label " ++ jobStateColor job)]
                     [text "Retries"
                     ,div [class "detail"]
                         [job.retries |> String.fromInt |> text
                         ]
                     ]
                 ]
            ,jobStateLabel job
            ,div [class "ui basic label"]
                [Util.Time.formatDateTime job.submitted |> text
                ]
            ]
        ]

jobStateColor: JobDetail -> String
jobStateColor job =
    case job.state of
        "success" -> "green"
        "failed" -> "red"
        "canceled" ->  "orange"
        "stuck" -> "purple"
        "scheduled" -> "blue"
        "waiting" -> "grey"
        _ -> ""

jobStateLabel: JobDetail -> Html Msg
jobStateLabel job =
    let
        col = jobStateColor job
    in
        div [class ("ui label " ++ col)]
            [text job.state
            ]
