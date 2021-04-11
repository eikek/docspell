module Messages.Page.CollectiveSettings exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.CollectiveSettingsForm
import Messages.Comp.SourceManage
import Messages.Comp.UserManage


type alias Texts =
    { basics : Messages.Basics.Texts
    , userManage : Messages.Comp.UserManage.Texts
    , collectiveSettingsForm : Messages.Comp.CollectiveSettingsForm.Texts
    , sourceManage : Messages.Comp.SourceManage.Texts
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
    , userManage = Messages.Comp.UserManage.gb
    , collectiveSettingsForm = Messages.Comp.CollectiveSettingsForm.gb
    , sourceManage = Messages.Comp.SourceManage.gb
    , collectiveSettings = "Collective Settings"
    , insights = "Insights"
    , sources = "Sources"
    , settings = "Settings"
    , users = "Users"
    , user = "User"
    , collective = "Collective"
    , size = "Size"
    }
