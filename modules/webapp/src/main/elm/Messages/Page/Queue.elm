module Messages.Page.Queue exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
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
    , formatDateTime : Int -> String
    , sidebarTitle : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , currentlyRunning = "Currently Running"
    , queue = "Jobs"
    , waiting = "Waiting"
    , errored = "Errored"
    , success = "Success"
    , cancelled = "Cancelled"
    , noJobsRunning = "No jobs currently running."
    , noJobsDisplay = "No jobs to display."
    , noJobsWaiting = "No waiting jobs."
    , noJobsFailed = "No failed jobs to display."
    , noJobsSuccess = "No succesful jobs to display."
    , noJobsCancelled = "No cancelled jobs to display."
    , deleteThisJob = "Cancel/Delete this job?"
    , showLog = "Show log"
    , remove = "Remove"
    , retries = "Retries"
    , changePriority = "Change priority of this job"
    , prio = "Prio"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.English
    , sidebarTitle = "Processing"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , currentlyRunning = "Wird ausgeführt"
    , queue = "Jobs"
    , waiting = "Wartend"
    , errored = "Fehlerhaft"
    , success = "Erfolgreich"
    , cancelled = "Abgebrochhen"
    , noJobsRunning = "Es werden keine Jobs ausgeführt."
    , noJobsDisplay = "Keine Jobs vorhanden."
    , noJobsWaiting = "Keine wartenden Jobs."
    , noJobsFailed = "Keine fehlgeschlagenen Jobs vorhanden."
    , noJobsSuccess = "Keine erfolgreichen Jobs vorhanden."
    , noJobsCancelled = "Keine abgebrochenen Jobs vorhanden."
    , deleteThisJob = "Job abbrechen/löschen?"
    , showLog = "Log anzeigen"
    , remove = "Entfernen"
    , retries = "Versuche"
    , changePriority = "Priorität des Jobs ändern"
    , prio = "Prio"
    , formatDateTime = DF.formatDateTimeLong Messages.UiLanguage.German
    , sidebarTitle = "Verarbeitung"
    }
