module Messages.Comp.FolderManage exposing (Texts, gb)

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
