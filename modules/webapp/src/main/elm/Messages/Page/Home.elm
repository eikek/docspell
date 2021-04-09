module Messages.Page.Home exposing (..)

import Messages.Basics
import Messages.Comp.ItemCardList
import Messages.Comp.SearchStatsView
import Messages.Page.HomeSideMenu


type alias Texts =
    { basics : Messages.Basics.Texts
    , itemCardList : Messages.Comp.ItemCardList.Texts
    , searchStatsView : Messages.Comp.SearchStatsView.Texts
    , sideMenu : Messages.Page.HomeSideMenu.Texts
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
    , itemCardList = Messages.Comp.ItemCardList.gb
    , searchStatsView = Messages.Comp.SearchStatsView.gb
    , sideMenu = Messages.Page.HomeSideMenu.gb
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
