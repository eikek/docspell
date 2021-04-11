module Messages.Page.Queue exposing (Texts, gb)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , currentlyRunning : String
    , queue : String
    , waiting : String
    , errored : String
    , success : String
    , cancelled : String
    , noJobsRunning : String
    , noJobsDisplay : String
    , noJobsWaiting : String
    , noJobsFailed : String
    , noJobsSuccess : String
    , noJobsCancelled : String
    , deleteThisJob : String
    , showLog : String
    , remove : String
    , retries : String
    , changePriority : String
    , prio : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , currentlyRunning = "Currently Running"
    , queue = "Queue"
    , waiting = "Waiting"
    , errored = "Errored"
    , success = "Success"
    , cancelled = "Cancelled"
    , noJobsRunning = "No jobs currently running."
    , noJobsDisplay = "No jobs to display."
    , noJobsWaiting = "No waiting jobs."
    , noJobsFailed = "No failed jobs to display."
    , noJobsSuccess = "No succesfull jobs to display."
    , noJobsCancelled = "No cancelled jobs to display."
    , deleteThisJob = "Cancel/Delete this job?"
    , showLog = "Show log"
    , remove = "Remove"
    , retries = "Retries"
    , changePriority = "Change priority of this job"
    , prio = "Prio"
    }
