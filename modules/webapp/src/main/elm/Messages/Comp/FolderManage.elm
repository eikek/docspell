{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Messages.Comp.FolderManage exposing
    ( Texts
    , de
    , gb
    )

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


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , folderDetail = Messages.Comp.FolderDetail.gb
    , folderTable = Messages.Comp.FolderTable.gb
    , showOwningFoldersOnly = "Show owning folders only"
    , createNewFolder = "Create a new folder"
    , newFolder = "New Folder"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , folderDetail = Messages.Comp.FolderDetail.de
    , folderTable = Messages.Comp.FolderTable.de
    , showOwningFoldersOnly = "Nur besitzende Ordner anzeigen"
    , createNewFolder = "Neuen Ordner anlegen"
    , newFolder = "Neuer Ordner"
    }
