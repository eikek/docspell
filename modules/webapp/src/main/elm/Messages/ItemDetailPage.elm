module Messages.ItemDetailPage exposing (..)

import Messages.ItemDetailComp


type alias Texts =
    { itemDetail : Messages.ItemDetailComp.Texts
    , editMetadata : String
    }


gb : Texts
gb =
    { itemDetail = Messages.ItemDetailComp.gb
    , editMetadata = "Edit Metadata"
    }


de : Texts
de =
    gb
