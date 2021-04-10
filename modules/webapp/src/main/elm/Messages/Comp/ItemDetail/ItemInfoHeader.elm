module Messages.Comp.ItemDetail.ItemInfoHeader exposing (..)

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , itemDate : String
    , dueDate : String
    , source : String
    , new : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , itemDate = "Item Date"
    , dueDate = "Due Date"
    , source = "Source"
    , new = "New"
    }
