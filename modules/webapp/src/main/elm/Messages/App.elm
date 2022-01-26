{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.App exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { collectiveProfile : String
    , userProfile : String
    , lightDark : String
    , logout : String
    , items : String
    , manageData : String
    , uploadFiles : String
    , processingQueue : String
    , newInvites : String
    , help : String
    , newItemsArrived : String
    , dashboard : String
    }


gb : Texts
gb =
    { collectiveProfile = "Collective Profile"
    , userProfile = "User Profile"
    , lightDark = "Light/Dark"
    , logout = "Logout"
    , items = "Items"
    , manageData = "Manage Data"
    , uploadFiles = "Upload Files"
    , processingQueue = "Processing Queue"
    , newInvites = "New Invites"
    , help = "Help"
    , newItemsArrived = "New items arrived!"
    , dashboard = "Dashboard"
    }


de : Texts
de =
    { collectiveProfile = "Kollektivprofil"
    , userProfile = "Benutzerprofil"
    , lightDark = "Hell/Dunkel"
    , logout = "Abmelden"
    , items = "Dokumente"
    , manageData = "Daten verwalten"
    , uploadFiles = "Dateien hochladen"
    , processingQueue = "Verarbeitung"
    , newInvites = "Neue Einladung"
    , help = "Hilfe (English)"
    , newItemsArrived = "Neue Dokumente eingetroffen!"
    , dashboard = "Dashboard"
    }
