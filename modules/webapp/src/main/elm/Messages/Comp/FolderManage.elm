{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.FolderManage exposing
    ( Texts
    , de
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Basics
import Messages.Comp.FolderDetail
import Messages.Comp.FolderTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , folderDetail : Messages.Comp.FolderDetail.Texts
    , folderTable : Messages.Comp.FolderTable.Texts
    , showOwningFoldersOnly : String
    , createNewFolder : String
    , newFolder : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , folderDetail = Messages.Comp.FolderDetail.gb
    , folderTable = Messages.Comp.FolderTable.gb tz
    , showOwningFoldersOnly = "Show owning folders only"
    , createNewFolder = "Create a new folder"
    , newFolder = "New Folder"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , folderDetail = Messages.Comp.FolderDetail.de
    , folderTable = Messages.Comp.FolderTable.de tz
    , showOwningFoldersOnly = "Nur besitzende Ordner anzeigen"
    , createNewFolder = "Neuen Ordner anlegen"
    , newFolder = "Neuer Ordner"
    }
