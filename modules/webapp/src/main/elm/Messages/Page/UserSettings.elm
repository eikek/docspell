{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.UserSettings exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.ChangePasswordForm
import Messages.Comp.DueItemsTaskManage
import Messages.Comp.EmailSettingsManage
import Messages.Comp.ImapSettingsManage
import Messages.Comp.NotificationChannelManage
import Messages.Comp.NotificationHookManage
import Messages.Comp.OtpSetup
import Messages.Comp.PeriodicQueryTaskManage
import Messages.Comp.ScanMailboxManage
import Messages.Comp.UiSettingsManage


type alias Texts =
    { basics : Messages.Basics.Texts
    , changePasswordForm : Messages.Comp.ChangePasswordForm.Texts
    , uiSettingsManage : Messages.Comp.UiSettingsManage.Texts
    , emailSettingsManage : Messages.Comp.EmailSettingsManage.Texts
    , imapSettingsManage : Messages.Comp.ImapSettingsManage.Texts
    , notificationManage : Messages.Comp.DueItemsTaskManage.Texts
    , scanMailboxManage : Messages.Comp.ScanMailboxManage.Texts
    , notificationHookManage : Messages.Comp.NotificationHookManage.Texts
    , periodicQueryTask : Messages.Comp.PeriodicQueryTaskManage.Texts
    , channelManage : Messages.Comp.NotificationChannelManage.Texts
    , otpSetup : Messages.Comp.OtpSetup.Texts
    , userSettings : String
    , uiSettings : String
    , notifications : String
    , scanMailbox : String
    , emailSettingSmtp : String
    , emailSettingImap : String
    , channelSettings : String
    , changePassword : String
    , uiSettingsInfo : String
    , scanMailboxInfo1 : String
    , scanMailboxInfo2 : String
    , otpMenu : String
    , dueItems : String
    , notificationInfoText : String
    , webhookInfoText : String
    , dueItemsInfoText : String
    , periodicQueryInfoText : String
    , channels : String
    , channelInfoText : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , changePasswordForm = Messages.Comp.ChangePasswordForm.gb
    , uiSettingsManage = Messages.Comp.UiSettingsManage.gb
    , emailSettingsManage = Messages.Comp.EmailSettingsManage.gb
    , imapSettingsManage = Messages.Comp.ImapSettingsManage.gb
    , notificationManage = Messages.Comp.DueItemsTaskManage.gb tz
    , scanMailboxManage = Messages.Comp.ScanMailboxManage.gb tz
    , notificationHookManage = Messages.Comp.NotificationHookManage.gb
    , periodicQueryTask = Messages.Comp.PeriodicQueryTaskManage.gb tz
    , channelManage = Messages.Comp.NotificationChannelManage.gb
    , otpSetup = Messages.Comp.OtpSetup.gb tz
    , userSettings = "User Settings"
    , uiSettings = "UI Settings"
    , notifications = "Notifications"
    , scanMailbox = "Scan Mailbox"
    , emailSettingSmtp = "E-Mail Settings (SMTP)"
    , emailSettingImap = "E-Mail Settings (IMAP)"
    , changePassword = "Change Password"
    , channelSettings = "Notification Channels"
    , uiSettingsInfo =
        "These settings only affect the web ui. Settings can be stored to the collective or to your personal user. Personal settings are prefered when both values exist."
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
    , dueItems = "Due Items Query"
    , notificationInfoText = """

Docspell can send notification messages on various events. You can
choose from these channels to send messages:
[Matrix](https://matrix.org), [Gotify](https://gotify.net) or E-Mail.
At last you can send a plain http request with the event details in
its payload.

Additionally, you can setup queries that are executed periodically.
The results are send as a notification message.

A notification setting needs at least one communication channel, which
must be created before.

"""
    , webhookInfoText = """Webhooks execute http request upon certain events in docspell.
"""
    , dueItemsInfoText = """Docspell can notify you once the due dates of your items come closer.  """
    , periodicQueryInfoText = "You can define a custom query that gets executed periodically."
    , channels = "Notification Channels"
    , channelInfoText = "Channels are used to send notification messages."
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , changePasswordForm = Messages.Comp.ChangePasswordForm.de
    , uiSettingsManage = Messages.Comp.UiSettingsManage.de
    , emailSettingsManage = Messages.Comp.EmailSettingsManage.de
    , imapSettingsManage = Messages.Comp.ImapSettingsManage.de
    , notificationManage = Messages.Comp.DueItemsTaskManage.de tz
    , scanMailboxManage = Messages.Comp.ScanMailboxManage.de tz
    , notificationHookManage = Messages.Comp.NotificationHookManage.de
    , periodicQueryTask = Messages.Comp.PeriodicQueryTaskManage.de tz
    , channelManage = Messages.Comp.NotificationChannelManage.de
    , otpSetup = Messages.Comp.OtpSetup.de tz
    , userSettings = "Benutzereinstellung"
    , uiSettings = "Oberfläche"
    , notifications = "Benachrichtigungen"
    , scanMailbox = "E-Mail-Import"
    , emailSettingSmtp = "E-Mail-Einstellungen (SMTP)"
    , emailSettingImap = "E-Mail-Einstellungen (IMAP)"
    , channelSettings = "Benachrichtigungskanäle"
    , changePassword = "Passwort ändern"
    , uiSettingsInfo =
        "Diese Einstellungen sind für die Web-Oberfläche. Es kann entweder für das ganze Kollektiv Einstellungen gemacht werden oder persönliche. Die persönlichen Einstellungen werden bevorzugt, falls beide gesetzt sind."
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
    , dueItems = "Fällige Dokumente"
    , notificationInfoText = """

Docspell kann Benachrichtigungen bei gewissen Ereignissen versenden.
Es kann aus diesen Versandkanälen gewählt werden:
[Matrix](https://matrix.org), [Gotify](https://gotify.net) oder
E-Mail. Zusätzlich kann das HTTP request direkt empfangen werden, was
alle Details zu einem Ereignis enthält.

Ausserdem können periodische Suchabfragen erstellt werden, dessen
Ergebnis dann als Benachrichtigung versendet wird.

Für eine Notifikation ist ein Kommunikationskanal notwendig, der zuvor
erstellt werden muss.

"""
    , webhookInfoText = """Webhooks versenden HTTP Requests wenn bestimmte Ereignisse in Docspell auftreten."""
    , dueItemsInfoText = """Docspell kann dich benachrichtigen, sobald das Fälligkeitsdatum von Dokumenten näher kommt. """
    , periodicQueryInfoText = "Hier können beliebige Abfragen definiert werden, welche regelmäßig ausgeführt werden."
    , channels = "Benachrichtigungskanäle"
    , channelInfoText = "Über Kanäle werden Notifizierungen versendet."
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , changePasswordForm = Messages.Comp.ChangePasswordForm.fr
    , uiSettingsManage = Messages.Comp.UiSettingsManage.fr
    , emailSettingsManage = Messages.Comp.EmailSettingsManage.fr
    , imapSettingsManage = Messages.Comp.ImapSettingsManage.fr
    , notificationManage = Messages.Comp.DueItemsTaskManage.fr tz
    , scanMailboxManage = Messages.Comp.ScanMailboxManage.fr tz
    , notificationHookManage = Messages.Comp.NotificationHookManage.fr
    , periodicQueryTask = Messages.Comp.PeriodicQueryTaskManage.fr tz
    , channelManage = Messages.Comp.NotificationChannelManage.fr
    , otpSetup = Messages.Comp.OtpSetup.fr tz
    , userSettings = "Paramètres utilisateur"
    , uiSettings = "Paramètres UI"
    , notifications = "Notifications"
    , scanMailbox = "Scanner Boite Mail"
    , emailSettingSmtp = "Configuration E-Mail (SMTP)"
    , emailSettingImap = "Configuration E-Mail (IMAP)"
    , changePassword = "Changer le mot de passe"
    , channelSettings = "Canaux de notifications"
    , uiSettingsInfo =
        "Ces paramètres n'affectent que l'interface web. Les paramètres peuvent être enregistrer "
            ++ " dans les profiles utilsateur ou de groupe. Les paramètres utilsateurs ont la priorité."
    , scanMailboxInfo1 =
        "Docspell scanne les dossiers de votre boite mail pour importer vos mails. "
            ++ "La connexion doit être configurée"
            ++ " dans les paramètres email (imap)."
    , scanMailboxInfo2 =
        """
            Docpsell parcourt tous les dossiers configurés et importe
            les mails correspondant aux critères de recherche. Les
            mails précédement importés (avec documents toujours présents)
            sont ignorés. Après import d'un mail dans docspell, il
            est possible de le déplacer dans un autre répertoire, le
            supprimer ou ne rien faire. Dans ce dernier cas
            la programmation devra être ajustée afin de ne pas
            relir ce mail encore une fois."""
    , otpMenu = "Authentification à 2 facteurs"
    , dueItems = "requête des Documents à échéance"
    , notificationInfoText = """

Docspell peut envoyer des notifications pour divers événements. 
Les canaux suivants sont possible pour envoyer des message: 
[Matrix](https://matrix.org), [Gotify](https://gotify.net) or E-Mail.
Enfin il est possible d'envoyer de vrai requête http avec les détails
de l'événement contenus dans le payload.

De plus, il est possible de paramétrer des requêtes exécutées périodiquement
dont les résultats seront transmis via une notification.

Le paramétrage d'une notification nécessite la création au préalable d'au
moins un canal de communication.

"""
    , webhookInfoText = """Les webhooksWebhooks executent une requête http en réponse à certains évenements dans docspell.
"""
    , dueItemsInfoText = """Docspell peut vous notifier quand la data d'échéance de vos documents approche.  """
    , periodicQueryInfoText = "Des requêtes périodiques peuvent être définies."
    , channels = "Canaux de notification"
    , channelInfoText = "Les canaux sont utilisés pour envoyer des messages de notification."
    }
