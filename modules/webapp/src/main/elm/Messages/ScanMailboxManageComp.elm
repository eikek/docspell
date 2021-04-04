module Messages.ScanMailboxManageComp exposing (..)

import Messages.Basics
import Messages.ScanMailboxFormComp
import Messages.ScanMailboxTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , form : Messages.ScanMailboxFormComp.Texts
    , table : Messages.ScanMailboxTableComp.Texts
    , newTask : String
    , createNewTask : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , form = Messages.ScanMailboxFormComp.gb
    , table = Messages.ScanMailboxTableComp.gb
    , newTask = "New Task"
    , createNewTask = "Create a new scan mailbox task"
    }
