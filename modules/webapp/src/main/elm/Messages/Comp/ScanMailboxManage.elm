module Messages.Comp.ScanMailboxManage exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.ScanMailboxForm
import Messages.Comp.ScanMailboxTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , form : Messages.Comp.ScanMailboxForm.Texts
    , table : Messages.Comp.ScanMailboxTable.Texts
    , newTask : String
    , createNewTask : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , form = Messages.Comp.ScanMailboxForm.gb
    , table = Messages.Comp.ScanMailboxTable.gb
    , newTask = "New Task"
    , createNewTask = "Create a new scan mailbox task"
    }
