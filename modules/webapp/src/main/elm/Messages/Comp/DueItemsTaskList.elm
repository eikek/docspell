{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DueItemsTaskList exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Messages.Basics
import Messages.Data.ChannelType


type alias Texts =
    { basics : Messages.Basics.Texts
    , channelType : Messages.Data.ChannelType.Texts
    , summary : String
    , schedule : String
    , connection : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , channelType = Messages.Data.ChannelType.gb
    , summary = "Summary"
    , schedule = "Schedule"
    , connection = "Channel"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , channelType = Messages.Data.ChannelType.de
    , summary = "Kurzbeschreibung"
    , schedule = "Zeitplan"
    , connection = "Kanal"
    }

fr : Texts
fr =
    { basics = Messages.Basics.fr
    , channelType = Messages.Data.ChannelType.fr
    , summary = "Résumé"
    , schedule = "Programmation"
    , connection = "Canal"
    }
