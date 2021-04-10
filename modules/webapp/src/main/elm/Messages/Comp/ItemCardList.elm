module Messages.Comp.ItemCardList exposing (..)

import Messages.Comp.ItemCard


type alias Texts =
    { itemCard : Messages.Comp.ItemCard.Texts
    }


gb : Texts
gb =
    { itemCard = Messages.Comp.ItemCard.gb
    }
