module Messages.UserSettingsPage exposing (..)

import Messages.ChangePasswordFormComp
import Messages.EmailSettingsManageComp
import Messages.ImapSettingsManageComp
import Messages.NotificationManageComp
import Messages.ScanMailboxManageComp
import Messages.UiSettingsManageComp


type alias Texts =
    { changePasswordForm : Messages.ChangePasswordFormComp.Texts
    , uiSettingsManage : Messages.UiSettingsManageComp.Texts
    , emailSettingsManage : Messages.EmailSettingsManageComp.Texts
    , imapSettingsManage : Messages.ImapSettingsManageComp.Texts
    , notificationManage : Messages.NotificationManageComp.Texts
    , scanMailboxManage : Messages.ScanMailboxManageComp.Texts
    , userSettings : String
    , uiSettings : String
    , notifications : String
    , scanMailbox : String
    , emailSettingSmtp : String
    , emailSettingImap : String
    , changePassword : String
    , uiSettingsInfo : String
    , notificationInfoText : String
    , notificationRemindDaysInfo : String
    , scanMailboxInfo1 : String
    , scanMailboxInfo2 : String
    }


gb : Texts
gb =
    { changePasswordForm = Messages.ChangePasswordFormComp.gb
    , uiSettingsManage = Messages.UiSettingsManageComp.gb
    , emailSettingsManage = Messages.EmailSettingsManageComp.gb
    , imapSettingsManage = Messages.ImapSettingsManageComp.gb
    , notificationManage = Messages.NotificationManageComp.gb
    , scanMailboxManage = Messages.ScanMailboxManageComp.gb
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
    , notificationInfoText =
        """
            Docspell can notify you once the due dates of your items
            come closer. Notification is done via e-mail. You need to
            provide a connection in your e-mail settings."""
    , notificationRemindDaysInfo =
        "Docspell finds all items that are due in *Remind Days* days and sends this list via e-mail."
    , scanMailboxInfo1 =
        "Docspell can scan folders of your mailbox to import your mails. "
            ++ "You need to provide a connection in "
            ++ "your e-mail (imap) settings."
    , scanMailboxInfo2 =
        """
            Docspell goes through all configured folders and imports
            mails matching the search criteria. Mails are skipped if
            they were imported in a previous run and the corresponding
            items still exist. After submitting a mail into docspell,
            you can choose to move it to another folder, to delete it
            or to just leave it there. In the latter case you should
            adjust the schedule to avoid reading over the same mails
            again."""
    }


de : Texts
de =
    gb
