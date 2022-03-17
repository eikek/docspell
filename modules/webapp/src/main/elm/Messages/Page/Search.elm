{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Search exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.BookmarkQueryManage
import Messages.Comp.ItemCardList
import Messages.Comp.ItemMerge
import Messages.Comp.PublishItems
import Messages.Comp.SearchStatsView
import Messages.Page.SearchSideMenu


type alias Texts =
    { basics : Messages.Basics.Texts
    , itemCardList : Messages.Comp.ItemCardList.Texts
    , searchStatsView : Messages.Comp.SearchStatsView.Texts
    , sideMenu : Messages.Page.SearchSideMenu.Texts
    , itemMerge : Messages.Comp.ItemMerge.Texts
    , publishItems : Messages.Comp.PublishItems.Texts
    , bookmarkManage : Messages.Comp.BookmarkQueryManage.Texts
    , contentSearch : String
    , searchInNames : String
    , selectModeTitle : String
    , fullHeightPreviewTitle : String
    , fullWidthPreviewTitle : String
    , powerSearchPlaceholder : String
    , reallyReprocessQuestion : String
    , reallyDeleteQuestion : String
    , reallyRestoreQuestion : String
    , editSelectedItems : Int -> String
    , reprocessSelectedItems : Int -> String
    , deleteSelectedItems : Int -> String
    , undeleteSelectedItems : Int -> String
    , selectAllVisible : String
    , selectNone : String
    , resetSearchForm : String
    , exitSelectMode : String
    , mergeItemsTitle : Int -> String
    , publishItemsTitle : Int -> String
    , publishCurrentQueryTitle : String
    , shareResults : String
    , nothingSelectedToShare : String
    , loadMore : String
    , thatsAll : String
    , showItemGroups : String
    , listView : String
    , tileView : String
    , expandCollapseRows : String
    , bookmarkQuery : String
    , nothingToBookmark : String
    , submitMerge : String
    , mergeInfoText : String
    , mergeDeleteWarn : String
    , submitMergeTitle : String
    , cancelMergeTitle : String
    , mergeSuccessful : String
    , mergeInProcess : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , itemCardList = Messages.Comp.ItemCardList.gb tz
    , searchStatsView = Messages.Comp.SearchStatsView.gb
    , sideMenu = Messages.Page.SearchSideMenu.gb
    , itemMerge = Messages.Comp.ItemMerge.gb tz
    , publishItems = Messages.Comp.PublishItems.gb tz
    , bookmarkManage = Messages.Comp.BookmarkQueryManage.gb
    , contentSearch = "Content search…"
    , searchInNames = "Search in names…"
    , selectModeTitle = "Select Mode"
    , fullHeightPreviewTitle = "Full height preview"
    , fullWidthPreviewTitle = "Full width preview"
    , powerSearchPlaceholder = "Search query …"
    , reallyReprocessQuestion = "Really reprocess all selected items? Metadata of unconfirmed items may change."
    , reallyDeleteQuestion = "Really delete all selected items?"
    , reallyRestoreQuestion = "Really restore all selected items?"
    , editSelectedItems = \n -> "Edit " ++ String.fromInt n ++ " selected items"
    , reprocessSelectedItems = \n -> "Reprocess " ++ String.fromInt n ++ " selected items"
    , deleteSelectedItems = \n -> "Delete " ++ String.fromInt n ++ " selected items"
    , undeleteSelectedItems = \n -> "Restore " ++ String.fromInt n ++ " selected items"
    , selectAllVisible = "Select all visible"
    , selectNone = "Select none"
    , resetSearchForm = "Reset search form"
    , exitSelectMode = "Exit Select Mode"
    , mergeItemsTitle = \n -> "Merge " ++ String.fromInt n ++ " selected items"
    , publishItemsTitle = \n -> "Publish " ++ String.fromInt n ++ " selected items"
    , publishCurrentQueryTitle = "Publish current results"
    , shareResults = "Share Results"
    , nothingSelectedToShare = "Sharing everything doesn't work. You need to apply some criteria."
    , loadMore = "Load more…"
    , thatsAll = "That's all"
    , showItemGroups = "Group by month"
    , listView = "List view"
    , tileView = "Tile view"
    , expandCollapseRows = "Expand/Collapse all"
    , bookmarkQuery = "Bookmark query"
    , nothingToBookmark = "Nothing selected to bookmark"
    , submitMerge = "Merge"
    , mergeInfoText = "When merging items the first item in the list acts as the target. Every other items metadata is copied into the target item. If the property is a single value (like correspondent), it is only set if not already present. Tags, custom fields and attachments are added. The items can be reordered using drag&drop."
    , mergeDeleteWarn = "Note that all items but the first one is deleted after a successful merge!"
    , submitMergeTitle = "Merge the documents now"
    , cancelMergeTitle = "Back to select view"
    , mergeSuccessful = "Items merged successfully"
    , mergeInProcess = "Items are merged …"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , itemCardList = Messages.Comp.ItemCardList.de tz
    , searchStatsView = Messages.Comp.SearchStatsView.de
    , sideMenu = Messages.Page.SearchSideMenu.de
    , itemMerge = Messages.Comp.ItemMerge.de tz
    , publishItems = Messages.Comp.PublishItems.de tz
    , bookmarkManage = Messages.Comp.BookmarkQueryManage.de
    , contentSearch = "Volltextsuche…"
    , searchInNames = "Suche in Namen…"
    , selectModeTitle = "Auswahlmodus"
    , fullHeightPreviewTitle = "Vorschau in voller Höhe"
    , fullWidthPreviewTitle = "Vorschau in voller Breite"
    , powerSearchPlaceholder = "Suchanfrage…"
    , reallyReprocessQuestion = "Wirklich die gewählten Dokumente neu verarbeiten? Die Metadaten von nicht bestätigten Dokumenten können sich dabei ändern."
    , reallyDeleteQuestion = "Wirklich alle gewählten Dokumente löschen?"
    , reallyRestoreQuestion = "Wirklich alle gewählten Dokumente wiederherstellen?"
    , editSelectedItems = \n -> "Ändere " ++ String.fromInt n ++ " gewählte Dokumente"
    , reprocessSelectedItems = \n -> "Erneute Verarbeitung von " ++ String.fromInt n ++ " gewählten Dokumenten"
    , deleteSelectedItems = \n -> "Lösche " ++ String.fromInt n ++ " gewählte Dokumente"
    , undeleteSelectedItems = \n -> "Stelle " ++ String.fromInt n ++ " gewählte Dokumente wieder her"
    , selectAllVisible = "Wähle alle Dokumente in der Liste"
    , selectNone = "Wähle alle Dokumente ab"
    , resetSearchForm = "Suchformular zurücksetzen"
    , exitSelectMode = "Auswahlmodus verlassen"
    , mergeItemsTitle = \n -> String.fromInt n ++ " gewählte Dokumente zusammenführen"
    , publishItemsTitle = \n -> String.fromInt n ++ " gewählte Dokumente publizieren"
    , publishCurrentQueryTitle = "Aktuelle Ansicht publizieren"
    , shareResults = "Ergebnisse teilen"
    , nothingSelectedToShare = "Alles kann nicht geteilt werden; es muss etwas gesucht werden."
    , loadMore = "Mehr laden…"
    , thatsAll = "Mehr gibt es nicht"
    , showItemGroups = "nach Monat gruppieren"
    , listView = "Listenansicht"
    , tileView = "Kachelansicht"
    , expandCollapseRows = "Alle ein-/ausklappen"
    , bookmarkQuery = "Abfrage merken"
    , nothingToBookmark = "Keine Abfrage vorhanden"
    , submitMerge = "Zusammenführen"
    , mergeInfoText = "Beim Zusammenführen der Dokumente, wird das erste in der Liste als Zieldokument verwendet. Die Metadaten der anderen Dokumente werden der Reihe nach auf des Zieldokument geschrieben. Metadaten die nur einen Wert haben, werden nur gesetzt falls noch kein Wert existiert. Tags, Benutzerfelder und Anhänge werden zu dem Zieldokument hinzugefügt. Die Einträge können mit Drag&Drop umgeordnet werden."
    , mergeDeleteWarn = "Bitte beachte, dass nach erfolgreicher Zusammenführung alle anderen Dokumente gelöscht werden!"
    , submitMergeTitle = "Dokumente jetzt zusammenführen"
    , cancelMergeTitle = "Zurück zur Auswahl"
    , mergeSuccessful = "Die Dokumente wurden erfolgreich zusammengeführt."
    , mergeInProcess = "Dokumente werden zusammengeführt…"
    }


fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , itemCardList = Messages.Comp.ItemCardList.fr tz
    , searchStatsView = Messages.Comp.SearchStatsView.fr
    , sideMenu = Messages.Page.SearchSideMenu.fr
    , itemMerge = Messages.Comp.ItemMerge.fr tz
    , publishItems = Messages.Comp.PublishItems.fr tz
    , bookmarkManage = Messages.Comp.BookmarkQueryManage.fr
    , contentSearch = "Recherche..."
    , searchInNames = "Recherche par nom..."
    , selectModeTitle = "Select Mode"
    , fullHeightPreviewTitle = "Aperçu pleine hauteur   "
    , fullWidthPreviewTitle = "Aperçu pleine largeur"
    , powerSearchPlaceholder = "Requête..."
    , reallyReprocessQuestion = "Confirmer le retraitement de tous les documents sélectionnés? Les métadonnées des documents non validées pourront changer."
    , reallyDeleteQuestion = "Confirmer la suppression de tous les documents sélectionnés ?"
    , reallyRestoreQuestion = "Restorer tous les documents sélectionnés ?"
    , editSelectedItems = \n -> "Éditer " ++ String.fromInt n ++ " documents sélectionnés"
    , reprocessSelectedItems = \n -> "Retraiter " ++ String.fromInt n ++ " documents sélectionnés"
    , deleteSelectedItems = \n -> "Supprimer " ++ String.fromInt n ++ " documents sélectionnés"
    , undeleteSelectedItems = \n -> "Restorer " ++ String.fromInt n ++ " documents sélectionnés"
    , selectAllVisible = "Sélectionner tous les visible"
    , selectNone = "Sélectionner aucun"
    , resetSearchForm = "Réinitialiser le formulaire de recherche"
    , exitSelectMode = "Quitter le mode sélection"
    , mergeItemsTitle = \n -> "Fusionner " ++ String.fromInt n ++ " documents sélectionnés"
    , publishItemsTitle = \n -> "Publier " ++ String.fromInt n ++ " documents sélectionnés"
    , publishCurrentQueryTitle = "Publier les résultats en cours"
    , shareResults = "Partager les résultats"
    , nothingSelectedToShare = "Tout partager ne marche pas. Il faut donner des critères."
    , loadMore = "Charger plus..."
    , thatsAll = "C'est tout !"
    , showItemGroups = "Groupe par mois"
    , listView = "Vue en liste"
    , tileView = "Vue en tuile"
    , expandCollapseRows = "Étendre/Réduire tout"
    , bookmarkQuery = "Requête de favoris"
    , nothingToBookmark = "Rien n'est sélectionné en favori"
    , submitMerge = "Fusionner"
    , mergeInfoText = "Lors d'une fusion, le premier document sert de cible. Les métadonnées des autres documents sont ajoutées à la cible. Si la propriété est un valeur seule (comme correspondant), ceci est ajouté si pas déjà présent. Tags, champs personnalisés et pièces-jointes sont ajoutés. Les documents peuvent être réordonnés avec le glisser/déposer."
    , mergeDeleteWarn = "Veuillez noter que tous les documents sont supprimés après une fusion réussie !"
    , submitMergeTitle = "Lancer la fusion"
    , cancelMergeTitle = "Annuler la fusion"
    , mergeSuccessful = "Documents fusionnés avec succès"
    , mergeInProcess = "Fusion en cours ..."
    }
