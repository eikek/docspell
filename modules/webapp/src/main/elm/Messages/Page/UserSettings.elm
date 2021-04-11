module Messages.Page.UserSettings exposing (Texts, gb)

import Messages.Comp.ChangePasswordForm
import Messages.Comp.EmailSettingsManage
import Messages.Comp.ImapSettingsManage
import Messages.Comp.NotificationManage
import Messages.Comp.ScanMailboxManage
import Messages.Comp.UiSettingsManage


type alias Texts =
    { changePasswordForm : Messages.Comp.ChangePasswordForm.Texts
    , uiSettingsManage : Messages.Comp.UiSettingsManage.Texts
    , emailSettingsManage : Messages.Comp.EmailSettingsManage.Texts
    , imapSettingsManage : Messages.Comp.ImapSettingsManage.Texts
    , notificationManage : Messages.Comp.NotificationManage.Texts
    , scanMailboxManage : Messages.Comp.ScanMailboxManage.Texts
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
    { changePasswordForm = Messages.Comp.ChangePasswordForm.gb
    , uiSettingsManage = Messages.Comp.UiSettingsManage.gb
    , emailSettingsManage = Messages.Comp.EmailSettingsManage.gb
    , imapSettingsManage = Messages.Comp.ImapSettingsManage.gb
    , notificationManage = Messages.Comp.NotificationManage.gb
    , scanMailboxManage = Messages.Comp.ScanMailboxManage.gb
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
