{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.NotificationGotifyForm exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , gotifyUrl : String
    , appKey : String
    , priority : String
    , priorityInfo : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , gotifyUrl = "Gotify URL"
    , appKey = "App Key"
    , priority = "Priority"
    , priorityInfo = "A number denoting the importance of a message controlling notification behaviour. The higher the more important."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , gotifyUrl = "Gotify URL"
    , appKey = "App Key"
    , priority = "Priorität"
    , priorityInfo = "Eine Zahl, um die Wichtigkeit anzugeben (je höher desto wichtiger). Es steuert, wie eine Notifizierung erscheint."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , gotifyUrl = "Gotify URL"
    , appKey = "App Key"
    , priority = "Priorité"
    , priorityInfo = "A number denoting the importance of a message controlling notification behaviour. The higher the more important."
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , gotifyUrl = "URL do Gotify"
    , appKey = "Chave do App"
    , priority = "Prioridade"
    , priorityInfo = "Um número que indica a importância de uma mensagem e controla o comportamento das notificações. Quanto maior, mais importante."
    }
