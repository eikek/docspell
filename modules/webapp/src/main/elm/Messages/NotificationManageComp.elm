module Messages.NotificationManageComp exposing (..)

import Messages.Basics
import Messages.NotificationFormComp
import Messages.NotificationTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.NotificationFormComp.Texts
    , notificationTable : Messages.NotificationTableComp.Texts
    , newTask : String
    , createNewTask : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.NotificationFormComp.gb
    , notificationTable = Messages.NotificationTableComp.gb
    , newTask = "New Task"
    , createNewTask = "Create a new notification task"
    }
