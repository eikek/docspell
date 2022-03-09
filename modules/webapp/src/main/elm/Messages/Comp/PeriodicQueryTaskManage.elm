{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PeriodicQueryTaskManage exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.PeriodicQueryTaskForm
import Messages.Comp.PeriodicQueryTaskList
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.Comp.PeriodicQueryTaskForm.Texts
    , notificationTable : Messages.Comp.PeriodicQueryTaskList.Texts
    , httpError : Http.Error -> String
    , channelType : Messages.Data.ChannelType.Texts
    , newTask : String
    , createNewTask : String
    , taskCreated : String
    , taskUpdated : String
    , taskStarted : String
    , taskDeleted : String
    , matrix : String
    , gotify : String
    , email : String
    , httpRequest : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.Comp.PeriodicQueryTaskForm.gb tz
    , notificationTable = Messages.Comp.PeriodicQueryTaskList.gb
    , httpError = Messages.Comp.HttpError.gb
    , channelType = Messages.Data.ChannelType.gb
    , newTask = "New Task"
    , createNewTask = "Create a new notification task"
    , taskCreated = "Task created."
    , taskUpdated = "Task updated."
    , taskStarted = "Task started."
    , taskDeleted = "Task deleted."
    , matrix = "Matrix"
    , gotify = "Gotify"
    , email = "E-Mail"
    , httpRequest = "HTTP Request"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , notificationForm = Messages.Comp.PeriodicQueryTaskForm.de tz
    , notificationTable = Messages.Comp.PeriodicQueryTaskList.de
    , httpError = Messages.Comp.HttpError.de
    , channelType = Messages.Data.ChannelType.de
    , newTask = "Neuer Auftrag"
    , createNewTask = "Erstelle einen neuen Benachrichtigungsauftrag"
    , taskCreated = "Auftrag erstellt."
    , taskUpdated = "Auftrag aktualisiert."
    , taskStarted = "Auftrag gestartet."
    , taskDeleted = "Auftrag gelöscht."
    , matrix = "Matrix"
    , gotify = "Gotify"
    , email = "E-Mail"
    , httpRequest = "HTTP Request"
    }

fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , notificationForm = Messages.Comp.PeriodicQueryTaskForm.fr tz
    , notificationTable = Messages.Comp.PeriodicQueryTaskList.gb
    , httpError = Messages.Comp.HttpError.fr
    , channelType = Messages.Data.ChannelType.fr
    , newTask = "Nouvelle tâche"
    , createNewTask = "Créer une nouvelle tache de notification"
    , taskCreated = "Tâche créée."
    , taskUpdated = "Tâche mise à jours."
    , taskStarted = "Tâche démarrée"
    , taskDeleted = "Tâche supprimée"
    , matrix = "Matrix"
    , gotify = "Gotify"
    , email = "E-Mail"
    , httpRequest = "Requête HTTP"
    }
