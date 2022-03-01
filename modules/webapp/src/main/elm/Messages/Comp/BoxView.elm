{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxView exposing (Texts, de, gb)

import Data.TimeZone exposing (TimeZone)
import Messages.Comp.BoxQueryView
import Messages.Comp.BoxStatsView
import Messages.Comp.BoxUploadView


type alias Texts =
    { queryView : Messages.Comp.BoxQueryView.Texts
    , statsView : Messages.Comp.BoxStatsView.Texts
    , uploadView : Messages.Comp.BoxUploadView.Texts
    }


gb : TimeZone -> Texts
gb tz =
    { queryView = Messages.Comp.BoxQueryView.gb tz
    , statsView = Messages.Comp.BoxStatsView.gb
    , uploadView = Messages.Comp.BoxUploadView.gb
    }


de : TimeZone -> Texts
de tz =
    { queryView = Messages.Comp.BoxQueryView.de tz
    , statsView = Messages.Comp.BoxStatsView.de
    , uploadView = Messages.Comp.BoxUploadView.de
    }
