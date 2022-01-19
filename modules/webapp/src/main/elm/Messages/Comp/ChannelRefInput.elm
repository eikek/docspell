{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ChannelRefInput exposing
    ( Texts
    , de
    , gb
    )

import Messages.Basics
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , channelType : Messages.Data.ChannelType.Texts
    , placeholder : String
    , noCategory : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , channelType = Messages.Data.ChannelType.gb
    , placeholder = "Choose…"
    , noCategory = "No channel"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , channelType = Messages.Data.ChannelType.de
    , placeholder = "Wähle…"
    , noCategory = "Kein Kanal"
    }
