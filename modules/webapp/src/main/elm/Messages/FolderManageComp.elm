module Messages.FolderManageComp exposing (..)

import Messages.Basics
import Messages.FolderDetailComp
import Messages.FolderTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , folderDetail : Messages.FolderDetailComp.Texts
    , folderTable : Messages.FolderTableComp.Texts
    , showOwningFoldersOnly : String
    , createNewFolder : String
    , newFolder : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , folderDetail = Messages.FolderDetailComp.gb
    , folderTable = Messages.FolderTableComp.gb
    , showOwningFoldersOnly = "Show owning folders only"
    , createNewFolder = "Create a new folder"
    , newFolder = "New Folder"
    }
