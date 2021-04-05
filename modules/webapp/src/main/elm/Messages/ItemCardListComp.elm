module Messages.ItemCardListComp exposing (..)

import Messages.ItemCardComp


type alias Texts =
    { itemCard : Messages.ItemCardComp.Texts
    }


gb : Texts
gb =
    { itemCard = Messages.ItemCardComp.gb
    }
