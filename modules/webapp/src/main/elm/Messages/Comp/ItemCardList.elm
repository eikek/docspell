{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemCardList exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Comp.ItemCard


type alias Texts =
    { itemCard : Messages.Comp.ItemCard.Texts
    }


gb : TimeZone -> Texts
gb tz =
    { itemCard = Messages.Comp.ItemCard.gb tz
    }


de : TimeZone -> Texts
de tz =
    { itemCard = Messages.Comp.ItemCard.de tz
    }


fr : TimeZone -> Texts
fr tz =
    { itemCard = Messages.Comp.ItemCard.fr tz
    }
