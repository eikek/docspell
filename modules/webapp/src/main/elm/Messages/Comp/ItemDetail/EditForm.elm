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
    , formatDate = DF.formatDateLong Messages.UiLanguage.English
    , direction = Messages.Data.Direction.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , customFieldInput = Messages.Comp.CustomFieldMultiInput.de
    , createNewCustomField = "Erstelle neues Benutzer-Feld"
    , chooseDirection = "Wähle Richtung…"
    , dueDateTab = "Fälligkeits-Datum"
    , addNewOrg = "Neue Organisation hinzufügen"
    , editOrg = "Ändere Organisation"
    , chooseOrg = "Wähle Organisation"
    , addNewCorrespondentPerson = "Neuen Korrespondent (Person) hinzufügen"
    , editPerson = "Ändere die Person"
    , personOrgInfo = "Die ausgewählte Person gehört nicht zur gesetzten Organisation."
    , addNewConcerningPerson = "Neue betreffende Person hinzufügen"
    , addNewEquipment = "Neues Zubehör hinzufügen"
    , editEquipment = "Zubehör ändern"
    , suggestions = "Vorschläge"
    , formatDate = DF.formatDateLong Messages.UiLanguage.German
    , direction = Messages.Data.Direction.de
    }
