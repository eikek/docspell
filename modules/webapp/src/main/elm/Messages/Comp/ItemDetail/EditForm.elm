{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.EditForm exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
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


pt : TimeZone -> Texts
pt tz =
    { basics = Messages.Basics.pt
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.pt
    , tagDropdown = Messages.Comp.TagDropdown.pt
    , createNewCustomField = "Criar novo campo personalizado"
    , chooseDirection = "Escolha uma direção…"
    , dueDateTab = "Data de vencimento"
    , addNewOrg = "Adicionar nova organização"
    , editOrg = "Editar organização"
    , chooseOrg = "Escolha uma organização"
    , addNewCorrespondentPerson = "Adicionar nova pessoa correspondente"
    , editPerson = "Editar pessoa"
    , personOrgInfo = "A pessoa selecionada não pertence à organização selecionada."
    , addNewConcerningPerson = "Adicionar nova pessoa interessada"
    , addNewEquipment = "Adicionar novo equipamento"
    , editEquipment = "Editar equipamento"
    , suggestions = "Sugestões"
    , noSuggestions = "Nenhuma sugestão"
    , formatDate = DF.formatDateLong Messages.UiLanguage.Portuguese tz
    , direction = Messages.Data.Direction.pt
    }
