{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationMatrixForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , homeServer : String
    , roomId : String
    , accessKey : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , homeServer = "Homeserver URL"
    , roomId = "Room ID"
    , accessKey = "Access Token"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , homeServer = "Homeserver URL"
    , roomId = "Room ID"
    , accessKey = "Access Token"
    }
