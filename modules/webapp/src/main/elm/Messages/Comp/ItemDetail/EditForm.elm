{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.EditForm exposing
    ( Texts
    , de
    , gb
    )

import Data.Direction exposing (Direction)
import Messages.Basics
import Messages.Comp.CustomFieldMultiInput
import Messages.Data.Direction
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldInput : Messages.Comp.CustomFieldMultiInput.Texts
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


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.gb
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
    , formatDate = DF.formatDateLong Messages.UiLanguage.English
    , direction = Messages.Data.Direction.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.de
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
    , formatDate = DF.formatDateLong Messages.UiLanguage.German
    , direction = Messages.Data.Direction.de
    }
