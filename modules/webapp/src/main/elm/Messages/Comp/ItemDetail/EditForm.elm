{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.EditForm exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Data.Direction exposing (Direction)
import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.CustomFieldMultiInput
import Messages.Comp.TagDropdown
import Messages.Data.Direction
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagDropdown : Messages.Comp.TagDropdown.Texts
    , createNewCustomField : String
    , chooseDirection : String
    , dueDateTab : String
    , addNewOrg : String
    , editOrg : String
    , chooseOrg : String
    , addNewCorrespondentPerson : String
    , editPerson : String
    , personOrgInfo : String
    , addNewConcerningPerson : String
    , addNewEquipment : String
    , editEquipment : String
    , suggestions : String
    , noSuggestions : String
    , formatDate : Int -> String
    , direction : Direction -> String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagDropdown = Messages.Comp.TagDropdown.gb
    , createNewCustomField = "Create new custom field"
    , chooseDirection = "Choose a direction…"
    , dueDateTab = "Due Date"
    , addNewOrg = "Add new organization"
    , editOrg = "Edit organization"
    , chooseOrg = "Choose an organization"
    , addNewCorrespondentPerson = "Add new correspondent person"
    , editPerson = "Edit person"
    , personOrgInfo = "The selected person doesn't belong to the selected organization."
    , addNewConcerningPerson = "Add new concerning person"
    , addNewEquipment = "Add new equipment"
    , editEquipment = "Edit equipment"
    , suggestions = "Suggestions"
    , noSuggestions = "No suggestions"
    , formatDate = DF.formatDateLong Messages.UiLanguage.English tz
    , direction = Messages.Data.Direction.gb
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.de
    , tagDropdown = Messages.Comp.TagDropdown.de
    , createNewCustomField = "Erstelle neues Benutzerfeld"
    , chooseDirection = "Wähle Richtung…"
    , dueDateTab = "Fälligkeitsdatum"
    , addNewOrg = "Neue Organisation hinzufügen"
    , editOrg = "Ändere die Organisation"
    , chooseOrg = "Wähle eine Organisation"
    , addNewCorrespondentPerson = "Neue korrespondierende Person hinzufügen"
    , editPerson = "Ändere die Person"
    , personOrgInfo = "Die ausgewählte Person gehört nicht zur gewählten Organisation."
    , addNewConcerningPerson = "Neue betreffende Person hinzufügen"
    , addNewEquipment = "Neue Ausstattung hinzufügen"
    , editEquipment = "Ausstattung ändern"
    , suggestions = "Vorschläge"
    , noSuggestions = "Keine Vorschläge"
    , formatDate = DF.formatDateLong Messages.UiLanguage.German tz
    , direction = Messages.Data.Direction.de
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.fr
    , tagDropdown = Messages.Comp.TagDropdown.fr
    , createNewCustomField = "Créer un nouveau champs personnalisé"
    , chooseDirection = "Choisir un sens…"
    , dueDateTab = "Date d'échéance"
    , addNewOrg = "Ajouter une nouvelle organisation"
    , editOrg = "Editer une organisation"
    , chooseOrg = "Choisir une organisation"
    , addNewCorrespondentPerson = "Ajouter un correspondant"
    , editPerson = "Editer uncorrespondant"
    , personOrgInfo = "Le correspondant n'appartient pas à l'organisation."
    , addNewConcerningPerson = "Ajouter une personne concernée"
    , addNewEquipment = "Ajouter un nouvel équipement"
    , editEquipment = "Editer un équipement"
    , suggestions = "Suggestions"
    , noSuggestions = "Aucune suggestion"
    , formatDate = DF.formatDateLong Messages.UiLanguage.French tz
    , direction = Messages.Data.Direction.fr
    }


ja : TimeZone -> Texts
ja tz =
    { basics = Messages.Basics.ja
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.ja
    , tagDropdown = Messages.Comp.TagDropdown.ja
    , createNewCustomField = "新しいカスタムフィールドを作成"
    , chooseDirection = "方向を選択…"
    , dueDateTab = "期限"
    , addNewOrg = "新しい組織の追加"
    , editOrg = "組織を編集"
    , chooseOrg = "組織を選択"
    , addNewCorrespondentPerson = "新しい通信相手の追加"
    , editPerson = "人物を編集"
    , personOrgInfo = "選択したユーザーは、選択した組織に属していません。"
    , addNewConcerningPerson = "新しい関係者の追加"
    , addNewEquipment = "新しい機器の追加"
    , editEquipment = "機器を編集"
    , suggestions = "提案"
    , noSuggestions = "提案はありません"
    , formatDate = DF.formatDateLong Messages.UiLanguage.Japanese tz
    , direction = Messages.Data.Direction.ja
    }
