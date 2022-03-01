{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ScanMailboxManage exposing
    ( Texts
    , de
    , gb
    )

import Data.TimeZone exposing (TimeZone)
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


gb : TimeZone -> Texts
gb tb =
    { basics = Messages.Basics.gb
    , form = Messages.Comp.ScanMailboxForm.gb tb
    , table = Messages.Comp.ScanMailboxTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newTask = "New Task"
    , createNewTask = "Create a new scan mailbox task"
    , taskCreated = "Task created."
    , taskUpdated = "Task updated."
    , taskStarted = "Task started."
    , taskDeleted = "Task deleted."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , form = Messages.Comp.ScanMailboxForm.de tz
    , table = Messages.Comp.ScanMailboxTable.de
    , httpError = Messages.Comp.HttpError.de
    , newTask = "Neuer Auftrag"
    , createNewTask = "Einen neuen E-Mail-Suchauftrag erstellen"
    , taskCreated = "Auftrag erstellt."
    , taskUpdated = "Auftrag aktualisiert."
    , taskStarted = "Auftrag gestartet."
    , taskDeleted = "Auftrag gelöscht."
    }
