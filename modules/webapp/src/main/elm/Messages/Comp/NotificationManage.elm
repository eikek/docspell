{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.NotificationManage exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.NotificationForm
import Messages.Comp.NotificationTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.Comp.NotificationForm.Texts
    , notificationTable : Messages.Comp.NotificationTable.Texts
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
    , notificationForm = Messages.Comp.NotificationForm.gb
    , notificationTable = Messages.Comp.NotificationTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , newTask = "New Task"
    , createNewTask = "Create a new notification task"
    , taskCreated = "Task created."
    , taskUpdated = "Task updated."
    , taskStarted = "Task started."
    , taskDeleted = "Task deleted."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , notificationForm = Messages.Comp.NotificationForm.de
    , notificationTable = Messages.Comp.NotificationTable.de
    , httpError = Messages.Comp.HttpError.de
    , newTask = "Neuer Auftrag"
    , createNewTask = "Erstelle einen neuen Benachrichtigungsauftrag"
    , taskCreated = "Auftrag erstellt."
    , taskUpdated = "Auftrag aktualisiert."
    , taskStarted = "Auftrag gestartet."
    , taskDeleted = "Auftrag gelöscht."
    }
