{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.Fields exposing
    ( de
    , fr
    , ja
    , gb
    )

import Data.Fields exposing (Field(..))


gb : Field -> String
gb field =
    case field of
        Tag ->
            "Tag"

        Folder ->
            "Folder"

        CorrOrg ->
            "Correspondent Organization"

        CorrPerson ->
            "Correspondent Person"

        ConcPerson ->
            "Concerning Person"

        ConcEquip ->
            "Concerned Equipment"

        Date ->
            "Date"

        DueDate ->
            "Due Date"

        Direction ->
            "Direction"

        PreviewImage ->
            "Preview Image"

        CustomFields ->
            "Custom Fields"

        SourceName ->
            "Item Source"


de : Field -> String
de field =
    case field of
        Tag ->
            "Tag"

        Folder ->
            "Ordner"

        CorrOrg ->
            "Korrespondierende Organisation"

        CorrPerson ->
            "Korrespondierende Person"

        ConcPerson ->
            "Betreffende Person"

        ConcEquip ->
            "Betreffende Ausstattung"

        Date ->
            "Datum"

        DueDate ->
            "Fälligkeitsdatum"

        Direction ->
            "Richtung"

        PreviewImage ->
            "Vorschaubild"

        CustomFields ->
            "Benutzerfelder"

        SourceName ->
            "Quelle"


fr : Field -> String
fr field =
    case field of
        Tag ->
            "Tag"

        Folder ->
            "Dossier"

        CorrOrg ->
            "Organisation correspondante"

        CorrPerson ->
            "Personne correspondante"

        ConcPerson ->
            "Personne concernée"

        ConcEquip ->
            "Équipement concerné"

        Date ->
            "Date"

        DueDate ->
            "Date d'échéance"

        Direction ->
            "Sens"

        PreviewImage ->
            "Aperçu"

        CustomFields ->
            "Champs personnalisés"

        SourceName ->
            "Source du document"


ja : Field -> String
ja field =
    case field of
        Tag ->
            "タグ"

        Folder ->
            "フォルダ"

        CorrOrg ->
            "対応組織"

        CorrPerson ->
            "対応者"

        ConcPerson ->
            "人物に関する"

        ConcEquip ->
            "関連機器"

        Date ->
            "日付"

        DueDate ->
            "期限"

        Direction ->
            "方向"

        PreviewImage ->
            "画像のプレビュー"

        CustomFields ->
            "カスタムフィールド"

        SourceName ->
            "アイテムソース"
