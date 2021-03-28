module Messages.CollectiveSettingsPage exposing (..)

import Messages.Basics
import Messages.CollectiveSettingsFormComp
import Messages.SourceManageComp
import Messages.UserManageComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , userManage : Messages.UserManageComp.Texts
    , collectiveSettingsForm : Messages.CollectiveSettingsFormComp.Texts
    , sourceManage : Messages.SourceManageComp.Texts
    , collectiveSettings : String
    , insights : String
    , sources : String
    , settings : String
    , users : String
    , user : String
    , collective : String
    , size : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , userManage = Messages.UserManageComp.gb
    , collectiveSettingsForm = Messages.CollectiveSettingsFormComp.gb
    , sourceManage = Messages.SourceManageComp.gb
    , collectiveSettings = "Collective Settings"
    , insights = "Insights"
    , sources = "Sources"
    , settings = "Settings"
    , users = "Users"
    , user = "User"
    , collective = "Collective"
    , size = "Size"
    }


de : Texts
de =
    gb
