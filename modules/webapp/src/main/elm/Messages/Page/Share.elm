{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.Share exposing (..)

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.DownloadAll
import Messages.Comp.HttpError
import Messages.Comp.ItemCardList
import Messages.Comp.SearchMenu
import Messages.Comp.SharePasswordForm


type alias Texts =
    { searchMenu : Messages.Comp.SearchMenu.Texts
    , basics : Messages.Basics.Texts
    , itemCardList : Messages.Comp.ItemCardList.Texts
    , passwordForm : Messages.Comp.SharePasswordForm.Texts
    , downloadAll : Messages.Comp.DownloadAll.Texts
    , httpError : Http.Error -> String
    , authFailed : String
    , fulltextPlaceholder : String
    , powerSearchPlaceholder : String
    , normalSearchPlaceholder : String
    , extendedSearch : String
    , showItemGroups : String
    , listView : String
    , tileView : String
    , downloadAllLabel : String
    }


gb : TimeZone -> Texts
gb tz =
    { searchMenu = Messages.Comp.SearchMenu.gb
    , basics = Messages.Basics.gb
    , itemCardList = Messages.Comp.ItemCardList.gb tz
    , passwordForm = Messages.Comp.SharePasswordForm.gb
    , downloadAll = Messages.Comp.DownloadAll.gb
    , authFailed = "This share does not exist."
    , httpError = Messages.Comp.HttpError.gb
    , fulltextPlaceholder = "Fulltext search…"
    , powerSearchPlaceholder = "Extended search…"
    , extendedSearch = "Extended search query"
    , normalSearchPlaceholder = "Search…"
    , showItemGroups = "Group by month"
    , listView = "List view"
    , tileView = "Tile view"
    , downloadAllLabel = "Download all"
    }


de : TimeZone -> Texts
de tz =
    { searchMenu = Messages.Comp.SearchMenu.de
    , basics = Messages.Basics.de
    , itemCardList = Messages.Comp.ItemCardList.de tz
    , passwordForm = Messages.Comp.SharePasswordForm.de
    , downloadAll = Messages.Comp.DownloadAll.de
    , authFailed = "Diese Freigabe existiert nicht."
    , httpError = Messages.Comp.HttpError.de
    , fulltextPlaceholder = "Volltextsuche…"
    , powerSearchPlaceholder = "Erweiterte Suche…"
    , extendedSearch = "Erweiterte Suchanfrage"
    , normalSearchPlaceholder = "Suche…"
    , showItemGroups = "nach Monat gruppieren"
    , listView = "Listenansicht"
    , tileView = "Kachelansicht"
    , downloadAllLabel = "Alles herunterladen"
    }


fr : TimeZone -> Texts
fr tz =
    { searchMenu = Messages.Comp.SearchMenu.fr
    , basics = Messages.Basics.fr
    , itemCardList = Messages.Comp.ItemCardList.fr tz
    , passwordForm = Messages.Comp.SharePasswordForm.fr
    , downloadAll = Messages.Comp.DownloadAll.fr
    , authFailed = "Ce partage n'existe pas."
    , httpError = Messages.Comp.HttpError.fr
    , fulltextPlaceholder = "Recherche en texte entier..."
    , powerSearchPlaceholder = "Recherche étendue…"
    , extendedSearch = "Requête de recherche étendue"
    , normalSearchPlaceholder = "Recherche…"
    , showItemGroups = "Grouper par mois"
    , listView = "Affichage liste"
    , tileView = "Affichage tuile"
    , downloadAllLabel = "Télécharger tout"
    }
