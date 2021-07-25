{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Messages.Page.Home exposing
    ( Texts
    , de
    , gb
    )

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
    { basics = Messages.Basics.de
    , itemCardList = Messages.Comp.ItemCardList.de
    , searchStatsView = Messages.Comp.SearchStatsView.de
    , sideMenu = Messages.Page.HomeSideMenu.de
    , contentSearch = "Volltextsuche…"
    , searchInNames = "Suche in Namen…"
    , selectModeTitle = "Auswahlmodus"
    , fullHeightPreviewTitle = "Vorschau in voller Höhe"
    , fullWidthPreviewTitle = "Vorschau in voller Breite"
    , powerSearchPlaceholder = "Suchanfrage…"
    , reallyReprocessQuestion = "Wirklich die gewählten Dokumente neu verarbeiten? Die Metadaten von nicht bestätigten Dokumenten kann sich dabei ändern."
    , reallyDeleteQuestion = "Wirklich alle gewählten Dokumente löschen?"
    , editSelectedItems = \n -> "Ändere " ++ String.fromInt n ++ " gewählte Dokumente"
    , reprocessSelectedItems = \n -> "Erneute Verarbeitung von " ++ String.fromInt n ++ " gewählten Dokumenten"
    , deleteSelectedItems = \n -> "Lösche " ++ String.fromInt n ++ " gewählte Dokumente"
    , selectAllVisible = "Wähle alle Dokumente in der Liste"
    , selectNone = "Wähle alle Dokumente ab"
    , resetSearchForm = "Suchformular zurücksetzen"
    , exitSelectMode = "Auswahlmodus verlassen"
    }
