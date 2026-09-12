{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ImapSettingsManage exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ImapSettingsForm
import Messages.Comp.ImapSettingsTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , imapForm : Messages.Comp.ImapSettingsForm.Texts
    , imapTable : Messages.Comp.ImapSettingsTable.Texts
    , httpError : Http.Error -> String
    , addNewImapSettings : String
    , newSettings : String
    , reallyDeleteSettings : String
    , deleteThisEntry : String
    , fillRequiredFields : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , imapForm = Messages.Comp.ImapSettingsForm.gb
    , imapTable = Messages.Comp.ImapSettingsTable.gb
    , httpError = Messages.Comp.HttpError.gb
    , addNewImapSettings = "Add new IMAP settings"
    , newSettings = "New connection"
    , reallyDeleteSettings = "Really delete this mail-box connection?"
    , deleteThisEntry = "Delete this settings entry"
    , fillRequiredFields = "Please fill required fields."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , imapForm = Messages.Comp.ImapSettingsForm.de
    , imapTable = Messages.Comp.ImapSettingsTable.de
    , httpError = Messages.Comp.HttpError.de
    , addNewImapSettings = "Neue IMAP-Einstellungen hinzufügen"
    , newSettings = "Neue Verbindung"
    , reallyDeleteSettings = "Diese Verbindung wirklich löschen?"
    , deleteThisEntry = "Lösche diese Verbindung"
    , fillRequiredFields = "Bitte die erforderlichen Felder ausfüllen."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , imapForm = Messages.Comp.ImapSettingsForm.fr
    , imapTable = Messages.Comp.ImapSettingsTable.fr
    , httpError = Messages.Comp.HttpError.fr
    , addNewImapSettings = "Ajouter un connexion IMAP"
    , newSettings = "Ajouter une nouvelle connexion"
    , reallyDeleteSettings = "Confirmer la suppression de cette connexion ?"
    , deleteThisEntry = "Supprimer cette entrée"
    , fillRequiredFields = "Veuillez compléter les champs requis"
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , imapForm = Messages.Comp.ImapSettingsForm.ja
    , imapTable = Messages.Comp.ImapSettingsTable.ja
    , httpError = Messages.Comp.HttpError.ja
    , addNewImapSettings = "新しいIMAP設定を追加"
    , newSettings = "新規接続"
    , reallyDeleteSettings = "このメールボックスの接続を本当に削除しますか？"
    , deleteThisEntry = "この設定項目を削除"
    , fillRequiredFields = "必須項目を入力してください。"
    }
