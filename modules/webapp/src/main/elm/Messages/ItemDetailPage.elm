module Messages.ItemDetailPage exposing (..)

import Messages.EditFormComp
import Messages.ItemDetailComp


type alias Texts =
    { itemDetail : Messages.ItemDetailComp.Texts
    , editForm : Messages.EditFormComp.Texts
    , editMetadata : String
    , collapseExpand : String
    }


gb : Texts
gb =
    { itemDetail = Messages.ItemDetailComp.gb
    , editForm = Messages.EditFormComp.gb
    , editMetadata = "Edit Metadata"
    , collapseExpand = "Collapse/Expand"
    }


de : Texts
de =
    gb
