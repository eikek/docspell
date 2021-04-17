module Messages.Comp.ScanMailboxManage exposing (Texts, gb)

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ScanMailboxForm
import Messages.Comp.ScanMailboxTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , form : Messages.Comp.ScanMailboxForm.Texts
    , table : Messages.Comp.ScanMailboxTable.Texts
    , httpError : Http.Error -> String
    , newTask : String
    , createNewTask : String
    , taskCreated : String
    , taskUpdated : String
    , taskStarted : String
    , taskDeleted : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , form = Messages.Comp.ScanMailboxForm.gb
    , table = Messages.Comp.ScanMailboxTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newTask = "New Task"
    , createNewTask = "Create a new scan mailbox task"
    , taskCreated = "Task created."
    , taskUpdated = "Task updated."
    , taskStarted = "Task started."
    , taskDeleted = "Task deleted."
    }
