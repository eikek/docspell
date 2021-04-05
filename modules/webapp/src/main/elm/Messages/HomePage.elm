module Messages.HomePage exposing (..)

import Messages.Basics
import Messages.HomeSideMenu
import Messages.ItemCardListComp
import Messages.SearchStatsViewComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , sideMenu : Messages.HomeSideMenu.Texts
    , itemCardList : Messages.ItemCardListComp.Texts
    , searchStatsView : Messages.SearchStatsViewComp.Texts
    , contentSearch : String
    , searchInNames : String
    , selectModeTitle : String
    , fullHeightPreviewTitle : String
    , fullWidthPreviewTitle : String
    , powerSearchPlaceholder : String
    , reallyReprocessQuestion : String
    , reallyDeleteQuestion : String
    , editSelectedItems : Int -> String
    , reprocessSelectedItems : Int -> String
    , deleteSelectedItems : Int -> String
    , selectAllVisible : String
    , selectNone : String
    , resetSearchForm : String
    , exitSelectMode : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , sideMenu = Messages.HomeSideMenu.gb
    , itemCardList = Messages.ItemCardListComp.gb
    , searchStatsView = Messages.SearchStatsViewComp.gb
    , contentSearch = "Content search…"
    , searchInNames = "Search in names…"
    , selectModeTitle = "Select Mode"
    , fullHeightPreviewTitle = "Full height preview"
    , fullWidthPreviewTitle = "Full width preview"
    , powerSearchPlaceholder = "Search query …"
    , reallyReprocessQuestion = "Really reprocess all selected items? Metadata of unconfirmed items may change."
    , reallyDeleteQuestion = "Really delete all selected items?"
    , editSelectedItems = \n -> "Edit " ++ String.fromInt n ++ " selected items"
    , reprocessSelectedItems = \n -> "Reprocess " ++ String.fromInt n ++ " selected items"
    , deleteSelectedItems = \n -> "Delete " ++ String.fromInt n ++ " selected items"
    , selectAllVisible = "Select all visible"
    , selectNone = "Select none"
    , resetSearchForm = "Reset search form"
    , exitSelectMode = "Exit Select Mode"
    }


de : Texts
de =
    gb
