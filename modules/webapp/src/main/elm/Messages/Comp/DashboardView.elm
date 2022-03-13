{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DashboardView exposing (Texts, de, fr, gb)

import Data.TimeZone exposing (TimeZone)
import Messages.Comp.BoxView


type alias Texts =
    { boxView : Messages.Comp.BoxView.Texts
    }


gb : TimeZone -> Texts
gb tz =
    { boxView = Messages.Comp.BoxView.gb tz
    }


de : TimeZone -> Texts
de tz =
    { boxView = Messages.Comp.BoxView.de tz
    }


fr : TimeZone -> Texts
fr tz =
    { boxView = Messages.Comp.BoxView.fr tz
    }
