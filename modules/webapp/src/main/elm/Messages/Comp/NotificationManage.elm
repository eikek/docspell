module Messages.Comp.NotificationManage exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.NotificationForm
import Messages.Comp.NotificationTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , notificationForm : Messages.Comp.NotificationForm.Texts
    , notificationTable : Messages.Comp.NotificationTable.Texts
    , newTask : String
    , createNewTask : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , notificationForm = Messages.Comp.NotificationForm.gb
    , notificationTable = Messages.Comp.NotificationTable.gb
    , newTask = "New Task"
    , createNewTask = "Create a new notification task"
    }
