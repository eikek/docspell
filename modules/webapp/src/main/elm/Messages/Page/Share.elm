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
    , loadMore : String
    , thatsAll : String
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
    , loadMore = "Load more…"
    , thatsAll = "That's all"
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
    , loadMore = "Mehr laden…"
    , thatsAll = "Mehr gibt es nicht"
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
    , loadMore = "Charger plus..."
    , thatsAll = "C'est tout !"
    }


ja : TimeZone -> Texts
ja tz =
    { searchMenu = Messages.Comp.SearchMenu.ja
    , basics = Messages.Basics.ja
    , itemCardList = Messages.Comp.ItemCardList.ja tz
    , passwordForm = Messages.Comp.SharePasswordForm.ja
    , downloadAll = Messages.Comp.DownloadAll.ja
    , authFailed = "この共有リンクは存在しません。"
    , httpError = Messages.Comp.HttpError.ja
    , fulltextPlaceholder = "全文検索中…"
    , powerSearchPlaceholder = "詳細検索…"
    , extendedSearch = "詳細検索クエリ"
    , normalSearchPlaceholder = "検索…"
    , showItemGroups = "月ごとにグループ化"
    , listView = "リスト表示"
    , tileView = "タイル表示"
    , downloadAllLabel = "すべてダウンロード"
    , loadMore = "さらに読み込む…"
    , thatsAll = "以上です"
    }
