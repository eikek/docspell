{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.ManageData exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.BookmarkManage
import Messages.Comp.CustomFieldManage
import Messages.Comp.EquipmentManage
import Messages.Comp.FolderManage
import Messages.Comp.OrgManage
import Messages.Comp.PersonManage
import Messages.Comp.TagManage


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagManage : Messages.Comp.TagManage.Texts
    , equipmentManage : Messages.Comp.EquipmentManage.Texts
    , orgManage : Messages.Comp.OrgManage.Texts
    , personManage : Messages.Comp.PersonManage.Texts
    , folderManage : Messages.Comp.FolderManage.Texts
    , customFieldManage : Messages.Comp.CustomFieldManage.Texts
    , bookmarkManage : Messages.Comp.BookmarkManage.Texts
    , manageData : String
    , bookmarks : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , tagManage = Messages.Comp.TagManage.gb
    , equipmentManage = Messages.Comp.EquipmentManage.gb
    , orgManage = Messages.Comp.OrgManage.gb
    , personManage = Messages.Comp.PersonManage.gb
    , folderManage = Messages.Comp.FolderManage.gb tz
    , customFieldManage = Messages.Comp.CustomFieldManage.gb tz
    , bookmarkManage = Messages.Comp.BookmarkManage.gb
    , manageData = "Manage Data"
    , bookmarks = "Bookmarks"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , tagManage = Messages.Comp.TagManage.de
    , equipmentManage = Messages.Comp.EquipmentManage.de
    , orgManage = Messages.Comp.OrgManage.de
    , personManage = Messages.Comp.PersonManage.de
    , folderManage = Messages.Comp.FolderManage.de tz
    , customFieldManage = Messages.Comp.CustomFieldManage.de tz
    , bookmarkManage = Messages.Comp.BookmarkManage.de
    , manageData = "Daten verwalten"
    , bookmarks = "Bookmarks"
    }

fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , tagManage = Messages.Comp.TagManage.fr
    , equipmentManage = Messages.Comp.EquipmentManage.fr
    , orgManage = Messages.Comp.OrgManage.fr
    , personManage = Messages.Comp.PersonManage.fr
    , folderManage = Messages.Comp.FolderManage.fr tz
    , customFieldManage = Messages.Comp.CustomFieldManage.fr tz
    , bookmarkManage = Messages.Comp.BookmarkManage.fr
    , manageData = "Gestion des métadonnées"
    , bookmarks = "Favoris"
    }
