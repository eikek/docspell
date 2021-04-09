module Messages.SearchMenuComp exposing (..)

import Messages.Basics
import Messages.CustomFieldMultiInputComp
import Messages.TagSelectComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.CustomFieldMultiInputComp.Texts
    , tagSelect : Messages.TagSelectComp.Texts
    , chooseDirection : String
    , choosePerson : String
    , chooseEquipment : String
    , inbox : String
    , fulltextSearch : String
    , searchInNames : String
    , switchSearchModes : String
    , contentSearch : String
    , searchInNamesPlaceholder : String
    , fulltextSearchInfo : String
    , nameSearchInfo : String
    , tagCategoryTab : String
    , folderTab : String
    , correspondentTab : String
    , organization : String
    , chooseOrganization : String
    , person : String
    , concerningTab : String
    , equipment : String
    , customFieldsTab : String
    , createCustomFieldTitle : String
    , dateTab : String
    , from : String
    , to : String
    , dueDateTab : String
    , dueFrom : String
    , dueTo : String
    , sourceTab : String
    , searchInItemSource : String
    , directionTab : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.CustomFieldMultiInputComp.gb
    , tagSelect = Messages.TagSelectComp.gb
    , chooseDirection = "Choose a direction…"
    , choosePerson = "Choose a person"
    , chooseEquipment = "Choose an equipment"
    , inbox = "Inbox"
    , fulltextSearch = "Fulltext Search"
    , searchInNames = "Search in names"
    , switchSearchModes = "Switch between text search modes"
    , contentSearch = "Content search…"
    , searchInNamesPlaceholder = "Search in various names…"
    , fulltextSearchInfo = "Fulltext search in document contents and notes."
    , nameSearchInfo = "Looks in correspondents, concerned entities, item name and notes."
    , tagCategoryTab = "Tag Categories"
    , folderTab = "Folder"
    , correspondentTab = "Correspondent"
    , organization = "Organization"
    , chooseOrganization = "Choose an organization"
    , person = "Person"
    , concerningTab = "Concerning"
    , equipment = "Equipment"
    , customFieldsTab = "Custom Fields"
    , createCustomFieldTitle = "Create a new custom field"
    , dateTab = "Date"
    , from = "From"
    , to = "To"
    , dueDateTab = "Due Date"
    , dueFrom = "Due From"
    , dueTo = "Due To"
    , sourceTab = "Source"
    , searchInItemSource = "Search in item source…"
    , directionTab = "Direction"
    }
