{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DueItemsTaskManage exposing
    ( Texts
    , de
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.DueItemsTaskForm
import Messages.Comp.DueItemsTaskList
import Messages.Comp.HttpError
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.Comp.DueItemsTaskForm.Texts
    , notificationTable : Messages.Comp.DueItemsTaskList.Texts
    , httpError : Http.Error -> String
    , channelType : Messages.Data.ChannelType.Texts
    , newTask : String
    , createNewTask : String
    , taskCreated : String
    , taskUpdated : String
    , taskStarted : String
    , taskDeleted : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.Comp.DueItemsTaskForm.gb tz
    , notificationTable = Messages.Comp.DueItemsTaskList.gb
    , httpError = Messages.Comp.HttpError.gb
    , channelType = Messages.Data.ChannelType.gb
    , newTask = "New Task"
    , createNewTask = "Create a new notification task"
    , taskCreated = "Task created."
    , taskUpdated = "Task updated."
    , taskStarted = "Task started."
    , taskDeleted = "Task deleted."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , notificationForm = Messages.Comp.DueItemsTaskForm.de tz
    , notificationTable = Messages.Comp.DueItemsTaskList.de
    , httpError = Messages.Comp.HttpError.de
    , channelType = Messages.Data.ChannelType.de
    , newTask = "Neuer Auftrag"
    , createNewTask = "Erstelle einen neuen Benachrichtigungsauftrag"
    , taskCreated = "Auftrag erstellt."
    , taskUpdated = "Auftrag aktualisiert."
    , taskStarted = "Auftrag gestartet."
    , taskDeleted = "Auftrag gelöscht."
    }
