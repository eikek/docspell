module Messages.Comp.SearchMenu exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.CustomFieldMultiInput
import Messages.Comp.FolderSelect
import Messages.Comp.TagSelect


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagSelect : Messages.Comp.TagSelect.Texts
    , folderSelect : Messages.Comp.FolderSelect.Texts
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
    , chooseOrganization : String
    , createCustomFieldTitle : String
    , from : String
    , to : String
    , dueDateTab : String
    , dueFrom : String
    , dueTo : String
    , sourceTab : String
    , searchInItemSource : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagSelect = Messages.Comp.TagSelect.gb
    , folderSelect = Messages.Comp.FolderSelect.gb
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
    , chooseOrganization = "Choose an organization"
    , createCustomFieldTitle = "Create a new custom field"
    , from = "From"
    , to = "To"
    , dueDateTab = "Due Date"
    , dueFrom = "Due From"
    , dueTo = "Due To"
    , sourceTab = "Source"
    , searchInItemSource = "Search in item source…"
    }
