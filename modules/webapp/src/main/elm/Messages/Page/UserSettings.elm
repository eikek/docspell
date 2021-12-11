{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.UserSettings exposing
    ( Texts
    , de
    , gb
    )

import Messages.Comp.ChangePasswordForm
import Messages.Comp.DueItemsTaskManage
import Messages.Comp.EmailSettingsManage
import Messages.Comp.ImapSettingsManage
import Messages.Comp.NotificationHookManage
import Messages.Comp.OtpSetup
import Messages.Comp.PeriodicQueryTaskManage
import Messages.Comp.ScanMailboxManage
import Messages.Comp.UiSettingsManage


type alias Texts =
    { changePasswordForm : Messages.Comp.ChangePasswordForm.Texts
    , uiSettingsManage : Messages.Comp.UiSettingsManage.Texts
    , emailSettingsManage : Messages.Comp.EmailSettingsManage.Texts
    , imapSettingsManage : Messages.Comp.ImapSettingsManage.Texts
    , notificationManage : Messages.Comp.DueItemsTaskManage.Texts
    , scanMailboxManage : Messages.Comp.ScanMailboxManage.Texts
    , notificationHookManage : Messages.Comp.NotificationHookManage.Texts
    , periodicQueryTask : Messages.Comp.PeriodicQueryTaskManage.Texts
    , otpSetup : Messages.Comp.OtpSetup.Texts
    , userSettings : String
    , uiSettings : String
    , notifications : String
    , scanMailbox : String
    , emailSettingSmtp : String
    , emailSettingImap : String
    , changePassword : String
    , uiSettingsInfo : String
    , scanMailboxInfo1 : String
    , scanMailboxInfo2 : String
    , otpMenu : String
    , webhooks : String
    , genericQueries : String
    , dueItems : String
    , notificationInfoText : String
    , webhookInfoText : String
    , dueItemsInfoText : String
    , periodicQueryInfoText : String
    }


gb : Texts
gb =
    { changePasswordForm = Messages.Comp.ChangePasswordForm.gb
    , uiSettingsManage = Messages.Comp.UiSettingsManage.gb
    , emailSettingsManage = Messages.Comp.EmailSettingsManage.gb
    , imapSettingsManage = Messages.Comp.ImapSettingsManage.gb
    , notificationManage = Messages.Comp.DueItemsTaskManage.gb
    , scanMailboxManage = Messages.Comp.ScanMailboxManage.gb
    , notificationHookManage = Messages.Comp.NotificationHookManage.gb
    , periodicQueryTask = Messages.Comp.PeriodicQueryTaskManage.gb
    , otpSetup = Messages.Comp.OtpSetup.gb
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
    , otpMenu = "Two Factor Authentication"
    , webhooks = "Webhooks"
    , genericQueries = "Generic Queries"
    , dueItems = "Due Items Query"
    , notificationInfoText = """

Docspell can send notification messages on various events. You can
choose from these channels to send messages:
[Matrix](https://matrix.org), [Gotify](https://gotify.net) or E-Mail.
At last you can send a plain http request with the event details in
its payload.

Additionally, you can setup queries that are executed periodically.
The results are send as a notification message.

When creating a new notification task, choose first the communication
channel.

"""
    , webhookInfoText = """Webhooks execute http request upon certain events in docspell.
"""
    , dueItemsInfoText = """Docspell can notify you once the due dates of your items come closer.  """
    , periodicQueryInfoText = "You can define a custom query that gets executed periodically."
    }


de : Texts
de =
    { changePasswordForm = Messages.Comp.ChangePasswordForm.de
    , uiSettingsManage = Messages.Comp.UiSettingsManage.de
    , emailSettingsManage = Messages.Comp.EmailSettingsManage.de
    , imapSettingsManage = Messages.Comp.ImapSettingsManage.de
    , notificationManage = Messages.Comp.DueItemsTaskManage.de
    , scanMailboxManage = Messages.Comp.ScanMailboxManage.de
    , notificationHookManage = Messages.Comp.NotificationHookManage.de
    , periodicQueryTask = Messages.Comp.PeriodicQueryTaskManage.de
    , otpSetup = Messages.Comp.OtpSetup.de
    , userSettings = "Benutzereinstellung"
    , uiSettings = "Oberfläche"
    , notifications = "Benachrichtigungen"
    , scanMailbox = "E-Mail-Import"
    , emailSettingSmtp = "E-Mail-Einstellungen (SMTP)"
    , emailSettingImap = "E-Mail-Einstellungen (IMAP)"
    , changePassword = "Passwort ändern"
    , uiSettingsInfo =
        "Diese Einstellungen sind für die Web-Oberfläche."
    , scanMailboxInfo1 =
        """Docspell kann Postfächer durchsuchen und E-Mails importieren. Dafür sind
E-Mail-Einstellungen (IMAP) notwendig."""
    , scanMailboxInfo2 =
        """
            Docspell durchsucht alle konfigurierten Ordner in einem
            Postfach nach E-Mails, die den Suchkriterien entsprechen.
            E-Mails werden übersprungen, falls sie im letzten Lauf
            schon importiert wurden (und das Dokument noch existiert).
            Nachdem eine E-Mail in Docspell importiert ist, kann sie
            gelöscht, in einen anderen Ordner verschoben werden oder
            sie kann unberührt belassen werden. Für den letzteren Fall
            ist es gut, die Kriterien so zu gestalten, dass die
            gleichen E-Mails möglichst nicht noch einmal eingelesen
            werden."""
    , otpMenu = "Zwei-Faktor-Authentifizierung"
    , webhooks = "Webhooks"
    , genericQueries = "Periodische Abfragen"
    , dueItems = "Fällige Dokumente"
    , notificationInfoText = """

Docspell kann Benachrichtigungen bei gewissen Ereignissen versenden.
Es kann aus diesen Versandkanälen gewählt werden:
[Matrix](https://matrix.org), [Gotify](https://gotify.net) oder
E-Mail. Zusätzlich kann das HTTP request direkt empfangen werden, was
alle Details zu einem Ereignis enthält.


Ausserdem können periodische Suchabfragen erstellt werden, dessen
Ergebnis dann als Benachrichtigung versendet wird.

Beim Erstellen eines neuen Auftrags muss zunächst der gewünschte
Versandkanal gewählt werden.

"""
    , webhookInfoText = """Webhooks versenden HTTP Requests wenn bestimmte Ereignisse in Docspell auftreten."""
    , dueItemsInfoText = """Docspell kann dich benachrichtigen, sobald das Fälligkeitsdatum von Dokumenten näher kommt. """
    , periodicQueryInfoText = "Hier können beliebige Abfragen definiert werden, welche regelmäßig ausgeführt werden."
    }
