module Messages.App exposing
    ( Texts
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
    }



-- de : Texts
-- de =
--     { collectiveProfile = "Kollektiv-Profil"
--     , userProfile = "Benutzer-Profil"
--     , lightDark = "Hell/Dunkel"
--     , logout = "Abmelden"
--     , items = "Dokumente"
--     , manageData = "Daten verwalten"
--     , uploadFiles = "Dateien hochladen"
--     , processingQueue = "Verarbeitung"
--     , newInvites = "Neue Einladung"
--     , help = "Hilfe (English)"
--     }
