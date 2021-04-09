module Messages.UiSettingsFormComp exposing (..)

import Data.Color exposing (Color)
import Data.Fields exposing (Field)
import Messages.ColorData
import Messages.FieldsData


type alias Texts =
    { general : String
    , showSideMenuByDefault : String
    , uiLanguage : String
    , itemSearch : String
    , maxResultsPerPageInfo : Int -> String
    , maxResultsPerPage : String
    , showBasicSearchStatsByDefault : String
    , enablePowerSearch : String
    , itemCards : String
    , maxNoteSize : String
    , maxNoteSizeInfo : Int -> String
    , sizeOfItemPreview : String
    , cardTitlePattern : String
    , togglePatternHelpText : String
    , cardSubtitlePattern : String
    , searchMenu : String
    , searchMenuTagCount : String
    , searchMenuTagCountInfo : String
    , searchMenuCatCount : String
    , searchMenuCatCountInfo : String
    , searchMenuFolderCount : String
    , searchMenuFolderCountInfo : String
    , itemDetail : String
    , browserNativePdfView : String
    , keyboardShortcutLabel : String
    , tagCategoryColors : String
    , colorLabel : Color -> String
    , chooseTagColorLabel : String
    , tagColorDescription : String
    , fields : String
    , fieldsInfo : String
    , fieldLabel : Field -> String
    }


gb : Texts
gb =
    { general = "General"
    , showSideMenuByDefault = "Show side menu by default"
    , uiLanguage = "UI Language"
    , itemSearch = "Item Search"
    , maxResultsPerPageInfo =
        \max ->
            "Maximum results in one page when searching items. At most "
                ++ String.fromInt max
                ++ "."
    , maxResultsPerPage = "Page size"
    , showBasicSearchStatsByDefault = "Show basic search statistics by default"
    , enablePowerSearch = "Enable power-user search bar"
    , itemCards = "Item Cards"
    , maxNoteSize = "Max. Note Length"
    , maxNoteSizeInfo =
        \max ->
            "Maximum size of the item notes to display in card view. Between 0 - "
                ++ String.fromInt max
                ++ "."
    , sizeOfItemPreview = "Size of item preview"
    , cardTitlePattern = "Card Title Pattern"
    , togglePatternHelpText = "Toggle pattern help text"
    , cardSubtitlePattern = "Card Subtitle Pattern"
    , searchMenu = "Search Menu"
    , searchMenuTagCount = "Number of tags in search menu"
    , searchMenuTagCountInfo = "How many tags to display in search menu at once. Others can be expanded. Use 0 to always show all."
    , searchMenuCatCount = "Number of categories in search menu"
    , searchMenuCatCountInfo = "How many categories to display in search menu at once. Others can be expanded. Use 0 to always show all."
    , searchMenuFolderCount = "Number of folders in search menu"
    , searchMenuFolderCountInfo = "How many folders to display in search menu at once. Other folders can be expanded. Use 0 to always show all."
    , itemDetail = "Item Detail"
    , browserNativePdfView = "Browser-native PDF preview"
    , keyboardShortcutLabel = "Use keyboard shortcuts for navigation and confirm/unconfirm with open edit menu."
    , tagCategoryColors = "Tag Category Colors"
    , colorLabel = Messages.ColorData.gb
    , chooseTagColorLabel = "Choose color for tag categories"
    , tagColorDescription = "Tags can be represented differently based on their category."
    , fields = "Fields"
    , fieldsInfo = "Choose which fields to display in search and edit menus."
    , fieldLabel = Messages.FieldsData.gb
    }
