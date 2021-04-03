module Messages.UserSettingsPage exposing (..)

import Messages.ChangePasswordFormComp
import Messages.UiSettingsManageComp


type alias Texts =
    { changePasswordForm : Messages.ChangePasswordFormComp.Texts
    , uiSettingsManage : Messages.UiSettingsManageComp.Texts
    , userSettings : String
    , uiSettings : String
    , notifications : String
    , scanMailbox : String
    , emailSettingSmtp : String
    , emailSettingImap : String
    , changePassword : String
    , uiSettingsInfo : String
    }


gb : Texts
gb =
    { changePasswordForm = Messages.ChangePasswordFormComp.gb
    , uiSettingsManage = Messages.UiSettingsManageComp.gb
    , userSettings = "User Settings"
    , uiSettings = "UI Settings"
    , notifications = "Notifications"
    , scanMailbox = "Scan Mailbox"
    , emailSettingSmtp = "E-Mail Settings (SMTP)"
    , emailSettingImap = "E-Mail Settings (IMAP)"
    , changePassword = "Change Password"
    , uiSettingsInfo =
        "These settings only affect the web ui. They are stored in the browser, "
            ++ "so they are separated between browsers and devices."
    }


de : Texts
de =
    gb
